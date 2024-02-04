// Importer les modules nécessaires
import readline from 'readline';
import fs from 'fs';

// Créer une interface de lecture pour la saisie utilisateur
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Définir la taille du plateau de jeu
const boardSize = { rows: 8, columns: 9 };

// Initialiser les joueurs avec leur plateau et leurs lettres
let players = { 1: { board: [], letters: [] }, 2: { board: [], letters: [] } };

// Variable pour suivre le tour de jeu
let tour = 1;

// Fonction pour initialiser le plateau d'un joueur
function initializeBoard(currentPlayer) {
  players[currentPlayer].board = Array.from({ length: boardSize.rows }, () => Array(boardSize.columns).fill(''));
}

// Fonction pour afficher le plateau d'un joueur
function displayBoard(player) {
  console.log(`Plateau du Joueur ${player} :`);
  console.log('   1 2 3 4 5 6 7 8 9');
  for (let i = 0; i < boardSize.rows; i++) {
    console.log(`${i + 1}  ${players[player].board[i].join(' ')}`);
  }
}

// Fonction pour initialiser les lettres d'un joueur
function initializePlayerLetters(currentPlayer) {
  for (let i = 0; i < 6; i++) {
    // Sélectionner une lettre aléatoire pour le joueur à partir de la liste des lettres disponibles
    const randomIndex = Math.floor(Math.random() * allLetters.length);
    const letter = allLetters[randomIndex];
    allLetters.splice(randomIndex, 1); // Retirer la lettre de allLetters
    players[currentPlayer].letters.push(letter);
  }
}

// Fonction pour vérifier si un mot est valide en lisant un fichier de dictionnaire
function isWordValid(word) {
  const validWords = fs.readFileSync('mots.txt', 'utf-8').split('\n');
  return validWords.includes(word);
}

// Fonction pour placer un mot sur le plateau
function placeWord(word, currentPlayer, jarnacOrNot, draw, ligne) {
  if (isWordValid(word)) {
    const usedLetters = [];
    let raw = -1;

    let playerJarnacOrNot;
    // On reprend ce code pour Jarnac, on teste donc si le joueur a demandé un jarnac
    if (jarnacOrNot) {
      playerJarnacOrNot = switchPlayer(currentPlayer);
    } else {
      playerJarnacOrNot = currentPlayer;
    }

    // Vérifier si le joueur possède toutes les lettres nécessaires
    if (word.split('').every(letter => players[currentPlayer].letters.includes(letter)) || (jarnacOrNot && word.split('').every(letter => players[switchPlayer(currentPlayer)].letters.includes(letter)))) {
      if (ligne!==-1){
        clearRow(ligne, playerJarnacOrNot);
      }
      // Trouver la première ligne vide sur le plateau du joueur
      for (let j = 0; j < 8; j++) {
        if (players[currentPlayer].board[j][0] === '') {
          raw = j;
          break;
        }
      }
      // Le joueur possède toutes les lettres, on peut placer le mot sur le plateau
      for (let i = 0; i < word.length; i++) {
          const letter = word[i].toUpperCase();
          players[currentPlayer].board[raw][i] = letter;
          usedLetters.push(letter);
    }
    } else {
      // Le joueur ne possède pas toutes les lettres nécessaires
      console.error('\x1b[31m%s\x1b[0m', 'Vous ne pouvez utiliser que les lettres qui vous ont été attribuées.');
      return false;
  }

    // Le mot est valide, retirer les lettres utilisées des lettres disponibles
    if (jarnacOrNot) {
      for (const usedLetter of usedLetters) {
        const letterIndex = players[switchPlayer(currentPlayer)].letters.indexOf(usedLetter);
        players[switchPlayer(currentPlayer)].letters.splice(letterIndex, 1);
      }
    } else {
      for (const usedLetter of usedLetters) {
        const letterIndex = players[currentPlayer].letters.indexOf(usedLetter);
        players[currentPlayer].letters.splice(letterIndex, 1);
      }
      if (draw == true) {
        drawRandomLetter(currentPlayer);
      }
    }
    return true;
  } else {
    console.error('\x1b[31m%s\x1b[0m', 'Le mot n\'est pas valide.');
    return false;
  }
}

// Fonction pour terminer le jeu et afficher le score
function endGame() {
  console.log(`Le jeu est fini !`);
  let score_1 = 0;
  let score_2 = 0;

  // Calculer le score pour chaque joueur en fonction des mots placés sur leur plateau
  for (let i = 0; i < players[1].board.length; i++) {
    let compteur_1 = 0;
    let compteur_2 = 0;
    for (let j = 2; j < players[1].board[0].length; j++) {
      if (players[1].board[i][j] !== '') {
        compteur_1 = (j + 1) * (j + 1);
      }
      if (players[2].board[i][j] !== '') {
        compteur_2 = (1 + j) * (1 + j);
      }
    }
    score_1 += compteur_1;
    score_2 += compteur_2;
  }

  // Afficher le résultat du jeu en fonction des scores
  if (score_1 > score_2) {
    console.log(`Joueur 1 a gagné avec ${score_1} points, Joueur 2 a fait ${score_2} points.`);
  } else {
    console.log(`Joueur 2 a gagné avec ${score_2} points, Joueur 1 a fait ${score_1} points.`);
  }
  console.log('Merci d\'avoir joué au Jarnac!');
  process.exit(0);
}

// Fonction pour écrire les coups dans un fichier
function ecritureDesCoups(texte, callback) {
  fs.appendFile("coups.txt", texte + '\n', (err) => {
    if (err) {
      callback(err);
    } else {
      callback(null);
    }
  });
}

// Fonction pour piocher une lettre aléatoire pour un joueur
function drawRandomLetter(currentPlayer) {
  if (allLetters.length != 0) {
    // Sélectionner une lettre aléatoire parmi les lettres disponibles
    const randomIndex = Math.floor(Math.random() * allLetters.length);
    const newLetter = allLetters[randomIndex];
    allLetters.splice(randomIndex, 1);
    players[currentPlayer].letters.push(newLetter);
    console.log("\x1b[34m",`Joueur ${currentPlayer}, vous avez pioché la lettre "${newLetter}"!`, "\x1b[0m");
  }
}

// Fonction pour vider une ligne du plateau
function clearRow(row, currentPlayer) {
  for (let i = 0; i < players[1].board[0].length; i++) {
    players[currentPlayer].board[row - 1][i] = '';
  }
}

// Fonction pour changer de joueur
function switchPlayer(currentPlayer) {
  return currentPlayer === 1 ? 2 : 1;
}

// Fonction pour piocher une lettre ou remplacer des lettres
function drawOrReplace(currentPlayer){
  console.log(`Joueur ${currentPlayer}, vos lettres : ${players[currentPlayer].letters.join(', ')}`);
  rl.question('-\nChoisissez une option:\n 1. Piocher une lettre\n 2. Remplacer 3 de vos lettres \nChoix : ', (optionpioche)=> {
      if (optionpioche === '1'){
        drawRandomLetter(currentPlayer);
        takeTurn(currentPlayer,currentPlayer);
      } else if (optionpioche === '2'){
        rl.question('Entrez les 3 lettres que vous souhaitez remplacer : ', (lettres_a_remplacer) => {
          lettres_a_remplacer.toUpperCase()
          // On teste si l'utilisateur a bien mis 3 lettres + si les 3 lettres sont bien présents dans la main du joueur
          if ((lettres_a_remplacer.length == 3) && (lettres_a_remplacer.split('').every(lettre => players[currentPlayer].letters.includes(lettre)))) {
            lettres_a_remplacer.split('').forEach(lettre => {
                const letterIndex = players[currentPlayer].letters.indexOf(lettre);
                if (letterIndex !== -1) {
                    allLetters.push(players[currentPlayer].letters[letterIndex]);
                    players[currentPlayer].letters.splice(letterIndex, 1);
                }
            });
            
            drawRandomLetter(currentPlayer);
            drawRandomLetter(currentPlayer);
            drawRandomLetter(currentPlayer);
            takeTurn(currentPlayer,currentPlayer)
          } else {
            console.error('\x1b[31m%s\x1b[0m', "Erreur lors du choix des 3 lettres");
            drawOrReplace(currentPlayer);
          }
      });
    } else {
      console.error('\x1b[31m%s\x1b[0m', "Choisissez une option valide !");
      drawOrReplace(currentPlayer);
    }
    
  });
}

// Fonction pour prendre le tour d'un joueur
function takeTurn(currentPlayer, oldPlayer) {
  // Vérifier si le jeu est terminé
  if (players[currentPlayer].board[7][2] !== '') {
    endGame();
    return;
  }

  // Afficher le plateau du joueur
  displayBoard(currentPlayer);

  // Piocher une lettre ou remplacer des lettres si nécessaire (uniquement disponible lors du deuxieme tour)
  if (tour > 2 && oldPlayer !== currentPlayer) {
    drawOrReplace(currentPlayer);
  }

  // Afficher les lettres du joueur
  console.log(`Joueur ${currentPlayer}, vos lettres : ${players[currentPlayer].letters.join(', ')}`);

  // Demander au joueur de choisir une option
  rl.question('-\nChoisissez une option :\n 1. Afficher un nouveau mot d\'au moins 3 lettres\n 2. Transformer un mot déjà affiché sur votre tableau\n 3. Jarnac\n 4. Passer votre tour\nChoix : ', (option) => {
    if (option === '1') {
      handleNewWord(currentPlayer, false);
    } else if (option === '2') {
      modifyExistingWord(currentPlayer, false);
    } else if (option == '3') {
      if (tour == 1) {
        console.error('\x1b[31m%s\x1b[0m', "Impossible de faire un jarnac au premier tour !");
        takeTurn(currentPlayer, currentPlayer);
      } else {
        jarnac(currentPlayer);
      }
    } else if (option === '4') {
      console.log(`Joueur ${currentPlayer} passe son tour.`);
      const nextPlayer = switchPlayer(currentPlayer);
      tour += 1;
      takeTurn(nextPlayer, currentPlayer);
    } else {
      console.error('\x1b[31m%s\x1b[0m', 'Option invalide. Veuillez choisir une option valide.');
      takeTurn(currentPlayer, currentPlayer);
    }
  });
}

// Fonction pour traiter un nouveau mot proposé par le joueur
function handleNewWord(currentPlayer, jarnacOrNot) {
  let playerJarnacOrNot;

  if (jarnacOrNot) {
    playerJarnacOrNot = switchPlayer(currentPlayer);
  } else {
    playerJarnacOrNot = currentPlayer;
  }

  rl.question('Entrez le mot que vous souhaitez utiliser : ', (word) => {
    if (word !== '') {
      word = word.toUpperCase();

      const YesOrNot=placeWord(word, currentPlayer, jarnacOrNot, true,-1);

      if (YesOrNot){

        if (jarnacOrNot){
          ecritureDesCoups(`Jarnac ! Le joueur ${currentPlayer} a joué le mot ${word} que le joueur ${switchPlayer(currentPlayer)} n'a pas vu !`, (erreur) => {
            if (erreur) {
              console.error('\x1b[31m%s\x1b[0m', 'Une erreur s\'est produite lors de l\'écriture :', erreur);
            }
          });
        }
        else {
          ecritureDesCoups(`Joueur ${currentPlayer} a joué le mot ${word}`, (erreur) => {
            if (erreur) {
              console.error('\x1b[31m%s\x1b[0m', 'Une erreur s\'est produite lors de l\'écriture :', erreur);
            }
          });
        }
        
      }
      
      takeTurn(currentPlayer, currentPlayer);
    } else {
      console.error('\x1b[31m%s\x1b[0m', "Le mot n'est pas valide !");
    }
  });
}

// Fonction pour modifier un mot existant sur le plateau
function modifyExistingWord(currentPlayer, jarnacOrNot) {
  let motUtile = "";
  let playerJarnacOrNot;
  if (jarnacOrNot) {
    playerJarnacOrNot = switchPlayer(currentPlayer);
  } else {
    playerJarnacOrNot = currentPlayer;
  }
  rl.question('Quelle ligne souhaitez-vous modifier ? : ', (ligne) => {
    if (/^\d+$/.test(ligne)) {
      // Construire le mot existant sur la ligne sélectionnée
      for (let i = 0; i < 8; i++) {
        const letter = players[playerJarnacOrNot].board[ligne - 1][i];
        motUtile = motUtile + letter;

        // Vérifier si la ligne sélectionnée contient un mot
        if (i === 0 && letter === '') {
          console.error('\x1b[31m%s\x1b[0m', "Choisissez une ligne avec un mot !");
          takeTurn(currentPlayer, currentPlayer);
        }

        // Ajouter les lettres de la ligne aux lettres disponibles
        if (letter !== '') {
          players[playerJarnacOrNot].letters.push(letter);
        }
      }
      // Si le joueur a joué un jarnac, alors on montre le jeu et le board de l'adversaire
      if (jarnacOrNot){
        console.log(`Joueur ${currentPlayer}, les lettres de votre adversaire : ${players[playerJarnacOrNot].letters.join(', ')}`);
      }
      else {
        console.log(`Joueur ${currentPlayer}, vos lettres : ${players[playerJarnacOrNot].letters.join(', ')}`);
      }

      // Demander au joueur d'entrer le nouveau mot
      rl.question('Entrez le mot que vous souhaitez utiliser : ', (word) => {
        word = word.toUpperCase();
        if (word !== '' && verifCaracteresDansMot(motUtile, word)) {
          const YesOrNot=placeWord(word, currentPlayer, jarnacOrNot, false,ligne);

          if (YesOrNot) {
            // Effacer la ligne choisie et placer le nouveau mot
            
            if (jarnacOrNot) {
              ecritureDesCoups(`Jarnac ! Le joueur ${currentPlayer} a volé le mot ${motUtile} du joueur ${switchPlayer(currentPlayer)} et la transformé en ${word}`, (erreur) => {
                if (erreur) {
                  console.error('\x1b[31m%s\x1b[0m', 'Une erreur s\'est produite lors de l\'écriture :', erreur);
                }
              });
            }
            else {
              ecritureDesCoups(`Joueur ${currentPlayer} a modifié le mot ${motUtile} en ${word}`, (erreur) => {
                if (erreur) {
                  console.error('\x1b[31m%s\x1b[0m', 'Une erreur s\'est produite lors de l\'écriture :', erreur);
                }
              });
            }
            
            takeTurn(currentPlayer, currentPlayer);
          } else {
            // Si le mot n'est pas valide, retirer les lettres ajoutées aux lettres disponibles
            let tailleMot = motUtile.length;
            for (let suppression = 0; suppression < tailleMot; suppression++) {
              players[playerJarnacOrNot].letters.pop();
            }
            console.error('\x1b[31m%s\x1b[0m',"Entrez un mot valide");
            takeTurn(currentPlayer, currentPlayer);
          }
        } else {
          console.error('\x1b[31m%s\x1b[0m', `Vous devez jouer des lettres du mot : ${motUtile} et ajouter une nouvelle lettre`)
          let tailleMot = motUtile.length;
          // De même, si y'a une erreur, on supprime les lettres pour éviter les doublons
          for (let suppression = 0; suppression < tailleMot; suppression++) {
            players[playerJarnacOrNot].letters.pop();
          }
          takeTurn(currentPlayer, currentPlayer);
        }
      });

    } else {
      console.error('\x1b[31m%s\x1b[0m', "Donnez le numéro d'une ligne");
      takeTurn(currentPlayer, currentPlayer);
    }
  });
}

// Fonction pour vérifier si toutes les lettres d'un mot existent dans un autre mot
function verifCaracteresDansMot(motPetit, motTot) {
  if (motPetit.length === motTot.length) {
    return false
  }
  for (let i = 0; i < motPetit.length; i++) {
    if (!motTot.includes(motPetit[i])) {
      return false;
    }
  }
  return true;
}

// Fonction pour l'option Jarnac
function jarnac(currentPlayer) {
  const player = switchPlayer(currentPlayer);
  displayBoard(player);
  console.log(`Joueur ${currentPlayer}, les lettres de votre adversaire sont : ${players[player].letters.join(', ')}`);
  rl.question('-\nChoisissez une option :\n1. Afficher un nouveau mot d\'au moins 3 lettres avec les lettres de votre adversaire \n2. Transformer un mot déjà affiché sur le tableau de votre adversaire \nChoix : ', (option) => {
    if (option === '1') {
      handleNewWord(currentPlayer, true);
    } else if (option === '2') {
      ecritureDesCoups(`Jarnac ! Le joueur ${currentPlayer} s'apprete à modifier un mot`, (erreur) => {
        if (erreur) {
          console.error('\x1b[31m%s\x1b[0m', 'Une erreur s\'est produite lors de l\'écriture :', erreur);
        }
      });
      modifyExistingWord(currentPlayer, true);
    } else {
      console.error('\x1b[31m%s\x1b[0m', 'Option invalide. Veuillez choisir une option valide.');
      takeTurn(currentPlayer, currentPlayer);
    }
  });
}

// Fonction principale pour démarrer le jeu
function playJarnac() {
  // Initialiser les plateaux et les lettres des joueurs
  initializeBoard(1);
  initializeBoard(2);
  initializePlayerLetters(1);
  initializePlayerLetters(2);
  // Commencer le premier tour
  takeTurn(1, 1);
}

// Assurer la fermeture de l'interface readline lorsque le jeu est terminé
rl.on('close', () => {
  console.log('Merci d\'avoir joué au Jarnac!');
  process.exit(0);
});

// Initialiser la liste de toutes les lettres disponibles
let allLetters = 'AAAAAAAAAAAAAABBBBCCCCCCCDDDDDEEEEEEEEEEEEEEEEEEEEFFGGGGHHIIIIIIIIIIIJKLMMMMMNNNNNNNNNOOOOOOOOPQRSSSSSSSTTTTTTTTTUUUUUUUUVVWXYZ'.split('');

// Créer un fichier pour enregistrer les coups
fs.writeFileSync("coups.txt", '');

// Démarrer le jeu
playJarnac();
