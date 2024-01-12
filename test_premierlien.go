package main

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
)

var tabliens []string

const port = ":8080"

func Home(w http.ResponseWriter, r *http.Request) {
	body := HTML("https://fr.wikipedia.org/wiki/Voltaire")
	fmt.Fprintf(w, body)

}

func Test(w http.ResponseWriter, r *http.Request) {
	body := HTML(tabliens[0])
	fmt.Fprintf(w, body)
}

func HTML(url string) string {
	// URL de la page web que vous souhaitez récupérer

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

	// Afficher le contenu HTML
	corps := string(body)
	tabliens = creation_lien(corps)

	fmt.Println(tabliens[0])

	souslien := tabliens[0][24:]
	http.HandleFunc(souslien, Test)
	return string(body)

}

func creation_lien(corps string) []string {
	prefixe := "https://fr.wikipedia.org"
	parts := strings.Split(corps, "<a href=")

	var tab_liens []string
	// Expression régulière pour vérifier si le lien contient "http" ou "cite-ref"
	re := regexp.MustCompile(`(http|cite_ref|cite_note)`)

	for _, part := range parts {
		liensettxt := strings.SplitN(part, "\"", -1)
		if !re.MatchString(liensettxt[1]) {
			// Si le lien ne contient ni "http" ni "cite-ref", ajouter le préfixe
			lien := prefixe + liensettxt[1]
			tab_liens = append(tab_liens, lien)
		}
	}
	return tab_liens
}

func main() {
	http.HandleFunc("/", Home)
	http.ListenAndServe(port, nil)

}
