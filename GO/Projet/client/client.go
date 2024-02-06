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
			fmt.Printf("Message received from server : %s", Message)
			// Recupération du fichier
			//downloadFile("client"+Message[:len(Message)-1], conn)
			fmt.Println("Closing connection")

			conn.Close()
			os.Exit(0)
		}
	}
}

func sendMessages(conn net.Conn, message string) {
	// Envoie de la requête au serveur
	_, err := io.WriteString(conn, message)
	if err != nil {
		fmt.Println("Error sending message to server : ", err)
		return
	}

	fmt.Printf("Message sent to server : %s", message)
}

func askScraping(conn net.Conn, wg *sync.WaitGroup) {
	defer wg.Done()

	// Demande si l'utilisateur veut scrapper un nouvea site ou ouvrir dans un serveur local un
	// site précédemment scrappé
	fmt.Print("Que voulez vous faire ?\n	1- Scraper un nouveau site\n	2- Ouvrir un site précédemment scrappé\n")
	scanner := bufio.NewScanner(os.Stdin)
	choice := "0"

	//Tester si l'utilisateur a bien entré 1 ou 2
	for choice != "1" && choice != "2" {
		fmt.Print("Entrez votre choix (1 ou 2): ")
		scanner.Scan()
		choice = scanner.Text()
	}

	// Demande de l'url du site à scraper et le nombre de lien à sraper si l'utilisateur a choisi 1
	if choice == "1" {
		// Demande de l'url du site à scraper
		fmt.Print("Entrez l'URL du site : ")
		scanner.Scan()
		url := scanner.Text()

		// Demande du nombre de lien à scraper
		fmt.Print("Entrez le nombre de lien à scraper : ")
		scanner.Scan()
		linkNumber := scanner.Text()

		// Combinaison des trois informations en une seule string
		message := fmt.Sprintf("%s %s %s\n", choice, url, linkNumber)

		// Envoie de la requête au serveur
		sendMessages(conn, message)
	} else {
		// Demande du nom du dossier à ouvrir
		fmt.Print("Entrez le nom du dossier à ouvrir : ")
		scanner.Scan()
		folderName := scanner.Text()

		// Combinaison des deux informations en une seule string
		message := fmt.Sprintf("%s %s\n", choice, folderName)

		// Envoie de la requête au serveur
		sendMessages(conn, message)
	}
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

/*
func downloadFile(fileToDownload string, conn net.Conn) {
	// Création du fichier
	file, err := os.Create(fileToDownload)
	if err != nil {
		fmt.Println("Error creating file : ", err)
		return
	}
	defer file.Close()

	// Copie du contenu du fichier reçu dans le fichier créé
	_, err = io.Copy(file, conn)
	if err != nil {
		fmt.Println("Error copying file : ", err)
		return
	}
}

*/
