package main

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
)

const port = ":8080"

var liste []string

func manger(url string) []string {
	prefixe := "https://fr.wikipedia.org"

	// Effectuer la requête HTTP GET
	response, err := http.Get(url)

	if err != nil {
		fmt.Printf("Erreur lors de la requête HTTP : %v", err)
		//return
	}
	// Lire le contenu de la réponse
	body, err := io.ReadAll(response.Body)

	if err != nil {
		fmt.Printf("Erreur lors de la lecture du corps de la réponse : %v", err)
		//return
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
	return tab_liens
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
	return string(body)

}

func Home(w http.ResponseWriter, r *http.Request) {
	body := HTML("https://fr.wikipedia.org/wiki/Voltaire")
	fmt.Fprintf(w, body)

}

func test(w http.ResponseWriter, r *http.Request, testurl string) {
	body := HTML(testurl)
	fmt.Fprintf(w, body)
}

func Lancement(petitlien string, url string) {
	testurl := url
	http.HandleFunc(petitlien, func(w http.ResponseWriter, r *http.Request) {
		test(w, r, testurl)
	})
}

func main() {

	testurl := "https://fr.wikipedia.org/wiki/Voltaire"
	http.HandleFunc("/", Home)
	liste = manger(testurl)
	for i := 200; i < 220; i++ {
		raccourci := liste[i][24:]
		go Lancement(raccourci, liste[i])
	}

	http.ListenAndServe(port, nil)
}
