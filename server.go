package main

import (
	"bufio"
	"fmt"
	"io"
	"net"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
)

func runAlgortihm(url string, nombre int) string {
	fmt.Println("Running algorithm")
	resultat := fmt.Sprintf("Résumé : Vous avez demandé pour le site %s avec le nombre %d.\n", url, nombre)
	fmt.Println("Algorithm finished")
	return resultat
}

func handleConnection(conn net.Conn, wg *sync.WaitGroup) {
	defer wg.Done()

	// Crée un scanner pour lire les données depuis la connexion
	scanner := bufio.NewScanner(conn)

	//Lis les données envoyées par le client
	if scanner.Scan() {
		line := scanner.Text()
		parts := strings.Fields(line)

		// Vérification du bon nombre d'arguments
		if len(parts) != 2 {
			fmt.Println("Invalid number of arguments")
			return
		}

		url := parts[0]
		nombre := parts[1]

		// Conversion du nombre en int
		nombreInt, err := strconv.Atoi(nombre)
		if err != nil {
			fmt.Println("Invalid number : ", err)
			return
		}

		// Exécution de l'algorithme
		resultat := runAlgortihm(url, nombreInt)

		// Envoie de la réponse au client
		_, err = io.WriteString(conn, resultat)
		if err != nil {
			fmt.Println("Error sending message to client : ", err)
			return
		} else {
			fmt.Printf("Message sent to client : %s\n", resultat)
		}
	}
}

func main() {
	// Crée un WaitGroup pour attendre la fin de toutes les goroutines
	var wg sync.WaitGroup

	// Crée un serveur TCP
	listener, err := net.Listen("tcp", ":8080")
	if err != nil {
		fmt.Println("Error creating server :", err)
		return
	}
	defer listener.Close()

	fmt.Println("Server waiting for connections...")

	// Signal d'arrêt du serveur
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, os.Interrupt)

	for {
		select {
		case <-signalChannel:
			fmt.Println("Server shutting down...")
			wg.Wait()
			os.Exit(0)
		default:
			//Attente d'une nouvelle connexion
			conn, err := listener.Accept()
			if err != nil {
				fmt.Println("Error accepting connection : ", err)
				continue
			} else {
				fmt.Println("New connection accepted.")
			}

			wg.Add(1)
			go handleConnection(conn, &wg)
		}
	}
}
