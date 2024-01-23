package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
)

const port = ":8080"

func Home(w http.ResponseWriter, r *http.Request, body string) {
	fmt.Fprintf(w, body)
}

func Lire(filePath string) {
	content, _ := os.ReadFile(filePath)
	fileContent := string(content)

	// Trouver la position de la séquence "corps_du_texte"
	index := strings.Index(fileContent, "\ncorps_du_texte\n")

	if index == -1 {
		fmt.Println("La séquence 'corps_du_texte' n'a pas été trouvée dans le fichier.")
		return
	}

	// Extraire ce qui se trouve avant et après la séquence
	titre := fileContent[:index]
	body := fileContent[index+len("\ncorps_du_texte\n"):]

	Lancement(titre, body)
}

func Lancement(titre string, body string) {
	http.HandleFunc(titre, func(w http.ResponseWriter, r *http.Request) { poster(w, r, body) })
}

func poster(w http.ResponseWriter, r *http.Request, body string) {
	fmt.Fprintf(w, body)
}

func main() {

	// chemin de votre fichier
	filePath := "HTML/Test0"
	// Lecture du fichier
	content, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Erreur lors de la lecture du fichier : %v\n", err)
		return
	}
	// Convertir le contenu en chaîne
	fileContent := string(content)

	// Trouver la position de la séquence "corps_du_texte"
	index := strings.Index(fileContent, "\ncorps_du_texte\n")

	if index == -1 {
		fmt.Println("La séquence 'corps_du_texte' n'a pas été trouvée dans le fichier.")
		return
	}

	// Extraire ce qui se trouve avant et après la séquence
	titre := fileContent[:index]
	body := fileContent[index+len("\ncorps_du_texte\n"):]

	http.HandleFunc(titre, func(w http.ResponseWriter, r *http.Request) { Home(w, r, body) })

	fmt.Printf("Le lien : localhost:8080%s \n", titre)
	fmt.Printf("Serveur écoutant sur le port %s...\n", port)

	infos, err := os.ReadDir("HTML")
	nb_fichiers := len(infos)

	for i := 1; i < nb_fichiers; i++ {
		Lire(fmt.Sprintf("HTML/Test%d", i))

	}

	err = http.ListenAndServe(port, nil)
	if err != nil {
		fmt.Printf("Erreur lors du démarrage du serveur : %v\n", err)
	}
}
