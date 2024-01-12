package main

import (
	"fmt"
	"io"
	"net/http"
)

const port = ":8080"

func Home(w http.ResponseWriter, r *http.Request) {
	body := HTML()
	fmt.Fprintf(w, body)
}

func HTML() string {
	// URL de la page web que vous souhaitez récupérer
	url := "https://fr.wikipedia.org/wiki/Voltaire"

	// Effectuer la requête HTTP GET
	response, err := http.Get(url)

	if err != nil {
		fmt.Printf("Erreur lors de la requête HTTP : %v", err)
		return ""
	}
	// Lire le contenu de la réponse
	body, err := io.ReadAll(response.Body)

	if err != nil {
		fmt.Printf("Erreur lors de la lecture du corps de la réponse : %v", err)
		return ""
	}

	print(string(body))
	// Afficher le contenu HTML
	return string(body)

}

func main() {

	http.HandleFunc("/", Home)
	http.ListenAndServe(port, nil)
}
