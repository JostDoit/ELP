import readline from 'readline';
import fs from 'fs';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const boardSize = { rows: 8, columns: 9 };
let players = { 1: { board: [], letters: [] }, 2: { board: [], letters: [] } };
let tour=1;

function initializeBoard(currentPlayer) {
  players[currentPlayer].board = Array.from({ length: boardSize.rows }, () => Array(boardSize.columns).fill(''));
}



function displayBoard(player) {
  console.log(`Joueur ${player}'s Board:`);
  console.log('   0 0 9 16 25 36 49 64 81');
  for (let i = 0; i < boardSize.rows; i++) {
    console.log(`${i + 1}  ${players[player].board[i].join(' ')}`);
  }
}

function initializePlayerLetters(currentPlayer) {
    for (let i = 0; i < 6; i++) {
      const randomIndex = Math.floor(Math.random() * allLetters.length);
      const letter = allLetters[randomIndex];
      allLetters.splice(randomIndex, 1); // Remove the letter from allLetters
      players[currentPlayer].letters.push(letter);
    }
}

function isWordValid(word) {
  const validWords = fs.readFileSync('ods6.txt', 'utf-8').split('\n');
  return validWords.includes(word);
}

function placeWord(word, currentPlayer) {
  if (isWordValid(word)) {
    const usedLetters = [];
    let row;

    for (let i = 0; i < word.length; i++) {
      const letter = word[i].toUpperCase();
      if (players[currentPlayer].letters.includes(letter)) {
        for (let j = 0; j < 8; j++) {
          if (players[currentPlayer].board[j][i] === '') {
            players[currentPlayer].board[j][i] = letter;
            usedLetters.push(letter);
            row = j + 1;
            break;
          }
        }
      } else {
        console.log('Vous ne pouvez utiliser que les lettres qui vous ont été attribuées. Annulez le mot.');
        clearRow(row, currentPlayer);
        return false;
      }
    }

    // Le mot est valide
    // Retirer les lettres utilisées des lettres disponibles
    for (const usedLetter of usedLetters) {
      const letterIndex = players[currentPlayer].letters.indexOf(usedLetter);
      players[currentPlayer].letters.splice(letterIndex, 1);
    }

    return true;
  } else {
    console.log('Le mot n\'est pas valide.');
    return false;
  }

  
}

function endGame(){
  console.log(`Le jeu est fini !`)
    let score_1=0;
    let score_2=0;
    
    for (let i=0;i<players[1].board.length;i++){
      let compteur_1=0;
      let compteur_2=0;
      for (let j=2;j<players[1].board[0].length;j++){
          if ( players[1].board[i][j]!==''){
            compteur_1=(j+1)*(j+1)
          }
          if ( players[2].board[i][j]!==''){
            compteur_2=(1+j)*(1+j)
          }
        }
        score_1+=compteur_1
        score_2+=compteur_2
      }
    if(score_1>score_2){
      console.log(`Joueur 1 a gagné avec ${score_1} points, Joueur 2 a fait ${score_2} points.`)
    } else {
      console.log(`Joueur 2 a gagné avec ${score_2} points, Joueur 1 a fait ${score_1} points.`)
    }
}

function ecritureDesCoups(texte,callback){
  fs.appendFile("coups.txt",texte + '\n',(err)=> {
    if(err){
      callback(err);
    } else {
      callback(null);
    }
  });
}

function drawRandomLetter(currentPlayer) {
  if (allLetters.length !=0) { 
    const randomIndex = Math.floor(Math.random() * allLetters.length);
    const newLetter = allLetters[randomIndex];
    allLetters.splice(randomIndex,1);
    players[currentPlayer].letters.push(newLetter);
    console.log(`Joueur ${currentPlayer}, vous avez pioché la lettre "${newLetter}"!`);
  }
}

function clearRow(row, currentPlayer) {
  for (let i = 0; i < players[1].board[0].length; i++) {
    players[currentPlayer].board[row - 1][i] = '';
  }
}

function switchPlayer(currentPlayer) {
  return currentPlayer === 1 ? 2 : 1;
}

function takeTurn(currentPlayer, firstTurn,oldPlayer) {


  if (players[currentPlayer].board[7][2] !== ''){
    endGame();   
    return;
  }
  displayBoard(currentPlayer);

  if (tour>2 && oldPlayer !== currentPlayer){
    rl.question('Choisissez une option:\n 1. Piocher une lettre\n 2. Remplacer 3 de vos lettres \n Choix:', (optionpioche)=> {
      if (optionpioche === '1'){
        drawRandomLetter(currentPlayer);
        takeTurn(currentPlayer,false,currentPlayer)
      } else if (optionpioche === '2'){
        console.log(`Joueur ${currentPlayer}, vos lettres : ${players[currentPlayer].letters.join(', ')}`);
        rl.question('Entrez les 3 lettres que vous souhaitez remplacer : ', (lettres_a_remplacer) => {
          if ((lettres_a_remplacer.length==3)&& (lettres_a_remplacer.split('').every(lettre => players[currentPlayer].letters.includes(lettre)))){
            lettres_a_remplacer.split('').forEach(lettre => allLetters.push(lettre));
            players[currentPlayer].letters = players[currentPlayer].letters.filter(lettre => !lettres_a_remplacer.split('').includes(lettre));
            
            drawRandomLetter(currentPlayer);
            drawRandomLetter(currentPlayer);
            drawRandomLetter(currentPlayer);
            takeTurn(currentPlayer,false,currentPlayer)
          } else {
            console.log("Erreur lors du choix");
            takeTurn(currentPlayer,firstTurn,currentPlayer);
          }
      });
    } else {
      takeTurn(currentPlayer,firstTurn,currentPlayer);
    }
    
  });
}
  console.log(`Joueur ${currentPlayer}, vos lettres : ${players[currentPlayer].letters.join(', ')}`);

  rl.question('Choisissez une option :\n1. Afficher un nouveau mot d\'au moins 3 lettres\n2. Transformer un mot déjà affiché sur votre tableau\n3. Passer votre tour\nChoix : ', (option) => {
    if (option === '1') {
      handleNewWord(currentPlayer);
    } else if (option === '2') {
      modifyExistingWord(currentPlayer);
    } else if (option === '3') {
      console.log(`Joueur ${currentPlayer} passe son tour.`);
      const nextPlayer = switchPlayer(currentPlayer);
      takeTurn(nextPlayer, false, currentPlayer);
      tour+=1;
    } else {
      console.log('Option invalide. Veuillez choisir une option valide.');
      takeTurn(currentPlayer, false, currentPlayer);
    }
  });
}

function handleNewWord(currentPlayer) {
  rl.question('Entrez le mot que vous souhaitez utiliser : ', (word) => {
    if (word !== '') {
      word = word.toUpperCase();
      placeWord(word, currentPlayer) 
      drawRandomLetter(currentPlayer);
      ecritureDesCoups(`Joueur ${currentPlayer} a joué le mot ${word}`,(erreur)=>{
      if (erreur){
        console.error('Une erreur s\'est produite:',erreur);
      }});
      takeTurn(currentPlayer, false);  
    }
    else {
      console.log("Entrez un mot valide")
    }
  });
}

function modifyExistingWord(currentPlayer) {
  let motUtile = "";
  rl.question('Quelle ligne souhaitez-vous modifier ? : ', (ligne) => {
    for (let i = 0; i < 8; i++) {
      const letter = players[currentPlayer].board[ligne - 1][i];
      if (i===0 && letter === ''){
        console.log("Choisissez une ligne avec un mot !")
        takeTurn(currentPlayer, false,currentPlayer)
      }
      motUtile=motUtile+letter;
      clearRow(ligne,currentPlayer)
      if (letter !== '') {
        players[currentPlayer].letters.push(letter);
      }
    }
    console.log(motUtile);
    console.log(`Joueur ${currentPlayer}, vos lettres : ${players[currentPlayer].letters.join(', ')}`);
    
    rl.question('Entrez le mot que vous souhaitez utiliser : ', (word) => {
      
      if (word !== '' && verifCaracteresDansMot(motUtile,word) ) {
        word = word.toUpperCase();
        placeWord(word, currentPlayer)
        takeTurn(currentPlayer, false,currentPlayer);
      }
      else {
        console.log(`Vous devez jouer des lettres du mot : ${motUtile}`)
        takeTurn(currentPlayer, false,currentPlayer);
      }
    });
    
  });
}

function verifCaracteresDansMot(motPetit, motTot) {
  for (let i = 0; i < motPetit.length; i++) {
      if (!motTot.includes(motPetit[i])) {
          return false;
      }
  }
  return true;
}

function playJarnac() {
  initializeBoard(1);
  initializeBoard(2);
  initializePlayerLetters(1);
  initializePlayerLetters(2);
  takeTurn(1, true,1);
}

// Assurez-vous de fermer l'interface readline quand le jeu est terminé
rl.on('close', () => {
  console.log('Merci d\'avoir joué au Jarnac!');
  process.exit(0);
});

// Lancer le jeu
let allLetters = 'AAAAAAAAAAAAAABBBBCCCCCCCDDDDDEEEEEEEEEEEEEEEEEEEEFFGGGGHHIIIIIIIIIIIJKLMMMMMNNNNNNNNNOOOOOOOOPQRSSSSSSSTTTTTTTTTUUUUUUUUVVWXYZ'.split('');
playJarnac();
