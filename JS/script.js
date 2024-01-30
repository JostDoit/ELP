import readline from 'readline';
import fs from 'fs';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

let board = [];
let playerLetters = { 1: [], 2: [] };

function initializeBoard() {
  for (let i = 0; i < 8; i++) {
    board.push(Array(9).fill(''));
  }
}

function displayBoard() {
  console.log('   1 2 3 4 5 6 7 8 9');
  for (let i = 0; i < 8; i++) {
    console.log(`${i + 1}  ${board[i].join(' ')}`);
  }
}

function initializePlayerLetters() {
  const allLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (let player = 1; player <= 2; player++) {
    for (let i = 0; i < 6; i++) {
      const randomIndex = Math.floor(Math.random() * allLetters.length);
      const letter = allLetters[randomIndex];
      playerLetters[player].push(letter);
    }
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
      if (playerLetters[currentPlayer].includes(letter)) {
        for (let j = 0; j < 8; j++) {
          if (board[j][i] === '') {
            board[j][i] = letter;
            usedLetters.push(letter);
            row = j + 1;
            break;
          }
        }
      } else {
        console.log('Vous ne pouvez utiliser que les lettres qui vous ont été attribuées. Annulez le mot.');
        clearBoard(row, usedLetters);
        return false;
      }
    }

    // Le mot est valide
    // Retirer les lettres utilisées des lettres disponibles
    for (const usedLetter of usedLetters) {
      const letterIndex = playerLetters[currentPlayer].indexOf(usedLetter);
      playerLetters[currentPlayer].splice(letterIndex, 1);
    }

    return true;
  } else {
    console.log('Le mot n\'est pas valide. Annulez le mot.');
    return false;
  }
}

function drawRandomLetter(currentPlayer, firstTurn) {
  if (!firstTurn) {
    const allLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const randomIndex = Math.floor(Math.random() * allLetters.length);
    const newLetter = allLetters[randomIndex];
    playerLetters[currentPlayer].push(newLetter);
    console.log(`Joueur ${currentPlayer}, vous avez pioché la lettre "${newLetter}"!`);
  }
}

function clearBoard(row, usedLetters) {
  for (let i = 0; i < usedLetters.length; i++) {
    board[row - 1][i] = '';
  }
}

function switchPlayer(currentPlayer) {
  return currentPlayer === 1 ? 2 : 1;
}

function takeTurn(currentPlayer, firstTurn) {
  displayBoard();
  console.log(`Joueur ${currentPlayer}, vos lettres : ${playerLetters[currentPlayer].join(', ')}`);
  
  drawRandomLetter(currentPlayer, firstTurn);

  rl.question('Entrez le mot que vous souhaitez utiliser : ', (word) => {
    if (word !== '') {
      word = word.toUpperCase();
      if (placeWord(word, currentPlayer)) {
        const nextPlayer = switchPlayer(currentPlayer);
        takeTurn(nextPlayer, false);
      } else {
        // Ne pas piocher de lettre en cas d'erreur
        takeTurn(currentPlayer, false);
      }
    } else {
      console.log('Le mot ne peut pas être vide. Essayez à nouveau.');
      // Ne pas piocher de lettre en cas d'erreur
      takeTurn(currentPlayer, false);
    }
  });
}

function playJarnac() {
  initializeBoard();
  initializePlayerLetters();
  takeTurn(1, true);
}

// Assurez-vous de fermer l'interface readline quand le jeu est terminé
rl.on('close', () => {
  console.log('Merci d\'avoir joué au Jarnac!');
  process.exit(0);
});

// Lancer le jeu
playJarnac();
