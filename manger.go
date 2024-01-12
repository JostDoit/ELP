package main

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
)

func main() {

	url := "https://fr.wikipedia.org/wiki/Voltaire"
	prefixe := "https://fr.wikipedia.org"

	// Effectuer la requête HTTP GET
	response, err := http.Get(url)

	if err != nil {
		fmt.Printf("Erreur lors de la requête HTTP : %v", err)
		return
	}
	// Lire le contenu de la réponse
	body, err := io.ReadAll(response.Body)

	if err != nil {
		fmt.Printf("Erreur lors de la lecture du corps de la réponse : %v", err)
		return
	}
	corps := string(body)
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

		//fmt.Println(liensettxt[1])e
	}

	for _, liens := range tab_liens {
		fmt.Println(liens)
	}

}
