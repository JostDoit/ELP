package main

import (
	"bufio"
	"fmt"
	"io"
	"net"
	"os"
	"sync"
)

func listen(conn net.Conn, wg *sync.WaitGroup) {
	defer wg.Done()
	buffer := bufio.NewReader(conn)
	for {
		Message, err := buffer.ReadString('\n')
		if err != nil {
			fmt.Println("Error reading message from server : ", err)
			return
		}

		if Message == "END\n" {
			fmt.Println("\nServer shutting down, closing connection")
			conn.Close()
			os.Exit(0)
		} else {
			//Affichage de la réponse du serveur
			fmt.Println("Server response : ", Message)
			fmt.Println("Closing connection")
			conn.Close()
			os.Exit(0)
		}
	}
}

func askScraping(conn net.Conn, wg *sync.WaitGroup) {
	defer wg.Done()

	// Demande de l'url du site à scraper et le nombre de lien à sraper
	fmt.Print("Entrez l'URL du site : ")
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	url := scanner.Text()

	fmt.Print("Entrez le nombre de lien à scraper : ")
	scanner.Scan()
	linkNumber := scanner.Text()

	// Combinaison des deux informations en une seule string
	message := fmt.Sprintf("%s %s\n", url, linkNumber)

	// Envoie de la requête au serveur
	_, err := io.WriteString(conn, message)
	if err != nil {
		fmt.Println("Error sending message to server : ", err)
		return
	}

	fmt.Printf("Message sent to server : %s", message)
}

func main() {

	// Connexion au serveur TCP
	conn, err := net.Dial("tcp", "localhost:8080")
	if err != nil {
		fmt.Println("Error connecting to server : ", err)
		return
	}

	defer conn.Close()
	fmt.Println("Connected to server")

	var wg sync.WaitGroup
	wg.Add(2)
	go askScraping(conn, &wg)
	go listen(conn, &wg)
	wg.Wait()
}
