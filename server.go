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
	"syscall"
	"time"
)

/*
Server : server structure
wg : WaitGroup to wait for all goroutines to finish
listener : TCP listener
shutdown : channel to signal shutdown
connection : channel to signal new connection
*/

type Server struct {
	wg         sync.WaitGroup
	listener   net.Listener
	shutdown   chan struct{}
	connection chan net.Conn
}

func runAlgortihm(url string, nombre int) string {
	fmt.Println("Running algorithm")
	resultat := fmt.Sprintf("Résumé : Vous avez demandé pour le site %s avec le nombre %d.\n", url, nombre)
	fmt.Println("Algorithm finished")
	return resultat
}

/*
newServer : create a new server
address : address to listen on
*/

func newServer(address string) (*Server, error) {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return nil, fmt.Errorf("Error creating server on address %s: %w", address, err)
	}

	return &Server{
		listener:   listener,
		shutdown:   make(chan struct{}),
		connection: make(chan net.Conn),
	}, nil
}

func (s *Server) acceptConnections() {
	defer s.wg.Done()
	for {
		select {
		case <-s.shutdown:
			fmt.Println("Accepting connections stopped")
			return
		default:
			conn, err := s.listener.Accept()
			if err != nil {
				fmt.Println("Error accepting connection : ", err)
				continue
			}
			s.connection <- conn
			fmt.Println("New connection accepted.")
		}
	}
}

func (s *Server) handleConnections() {
	defer s.wg.Done()

	for {
		select {
		case <-s.shutdown:
			fmt.Println("Handling connections stopped")
			return
		case conn := <-s.connection:
			go s.handleConnection(conn)
		}
	}
}

func (s *Server) handleConnection(conn net.Conn) {
	defer conn.Close()

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

func (s *Server) Start() {
	s.wg.Add(2)
	go s.acceptConnections()
	go s.handleConnections()
}

func (s *Server) Stop() {
	close(s.shutdown)
	s.listener.Close()

	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		fmt.Println("All goroutines finished")
		close(done)
	}()

	select {
	case <-done:
		return
	case <-time.After(5 * time.Second):
		fmt.Println("Server shutdown timed out")
	}
}

func main() {
	// Création du serveur TCP sur le port 8080
	s, err := newServer(":8080")
	if err != nil {
		fmt.Println("Error creating server :", err)
		os.Exit(1)
	}

	// Démarrage du serveur
	s.Start()
	fmt.Println("Server waiting for connections...")
	//defer listener.Close()

	//Attente d'un signal pour arrêter le serveur
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, syscall.SIGINT, syscall.SIGTERM)
	<-signalChannel

	//Arrêt du serveur
	fmt.Println("Server shutting down...")
	s.Stop()
	fmt.Println("Server stopped.")
}
