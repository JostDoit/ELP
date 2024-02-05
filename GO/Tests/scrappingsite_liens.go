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

func manger(lien string, corps string) []string {
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
			//lien_corrige, _ := url.QueryUnescape(lien)
			if verif_deja_la(tab_liens, lien) != true {
				tab_liens = append(tab_liens, lien)
			}

		}
	}
	return tab_liens
}

func verif_deja_la(tab_liens []string, chaine string) bool {
	for _, lien := range tab_liens {
		if lien == chaine {
			return true
		}
	}
	return false
}

func HTML(lien string) string {
	// URL de la page web que vous souhaitez récupérer

	// Effectuer la requête HTTP GET
	response, err := http.Get(lien)

	if err != nil {
		fmt.Printf("Erreur lors de la requête HTTP : %v", err)
		return ""
	}
	// Lire le contenu de la réponse
	body, err := io.ReadAll(response.Body)
	body_string := string(body)

	// Créer un map d'encodage URL à UTF-8
	urlToUTF8Map := map[string]string{
		"%C3%A9": "é",
		"%C3%A0": "à",
		"%C3%A7": "ç",
		"%C3%A8": "è",
		"%C3%89": "É",
		"%C3%A2": "â",
		"%27": "'",
		// Ajoutez d'autres paires clé-valeur au besoin
	}

	for encoded, utf8 := range urlToUTF8Map {
		body_string = strings.ReplaceAll(body_string, encoded, utf8)
	}

	if err != nil {
		fmt.Printf("Erreur lors de la lecture du corps de la réponse : %v", err)
		return ""
	}

	// Afficher le contenu HTML
	return body_string

}

func Home(w http.ResponseWriter, r *http.Request, body string) {
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
	body := HTML(testurl)
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		Home(w, r, body)
	})
	liste = manger(testurl, body)
	for i := 0; i < 1000; i++ {
		raccourci := liste[i][24:]
		go Lancement(raccourci, liste[i])
	}

	http.ListenAndServe(port, nil)
}
