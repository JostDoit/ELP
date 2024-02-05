package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"
)

func HTML(filePath string, URL string, wg *sync.WaitGroup) string {
	// Décrémente le compteur de la WaitGroup lorsque la fonction est terminée
	defer wg.Done()
	response, err := http.Get(URL)

	if err != nil {
		fmt.Printf("Erreur lors de la requête HTTP : %v", err)
		return ""
	}

	body, err := io.ReadAll(response.Body)

	if err != nil {
		fmt.Printf("Erreur lors de la lecture du corps de la réponse : %v", err)
		return ""
	}

	bodyString := string(body)

	urlToUTF8Map := map[string]string{
		"%C3%A9": "é",
		"%C3%A0": "à",
		"%C3%A7": "ç",
		"%C3%A8": "è",
		"%C3%89": "É",
		"%C3%A2": "â",
		"%20":    " ", // Ajout de l'espace en UTF-8
		"%27":    "'",
		// Ajoutez d'autres paires clé-valeur au besoin
	}
	for encoded, utf8 := range urlToUTF8Map {
		bodyString = strings.ReplaceAll(bodyString, encoded, utf8)
	}

	err2 := writetxt(filePath, bodyString, URL)

	if err2 != nil {
		fmt.Printf("Une erreur s'est produite : %s\n", err)
		return ""
	}

	return bodyString
}

func liens(URL string, corps string, prefixe string) []string {
	parts := strings.Split(corps, "<a href=")
	var tabLiens []string
	re := regexp.MustCompile(fmt.Sprintf(`(http|cite_ref|cite_note|%s| )`, URL[24:]))

	for _, part := range parts {

		liensEtTxt := strings.SplitN(part, "\"", -1)
		if !re.MatchString(liensEtTxt[1]) {
			lien := prefixe + liensEtTxt[1]
			if !verifSiDejaLa(tabLiens, lien) {
				tabLiens = append(tabLiens, lien)
			}
		}
	}
	return tabLiens
}

func verifSiDejaLa(tabLiens []string, chaine string) bool {
	for _, lien := range tabLiens {
		if lien == chaine {
			return true
		}
	}
	return false
}

func writetxt(filePath, corps string, lien string) error {
	raccourci := lien[24:]
	content := raccourci + "\ncorps_du_texte\n" + corps
	file, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.WriteString(content)
	if err != nil {
		return err
	}

	fmt.Printf("Le contenu a été écrit avec succès dans le fichier : %s\n", filePath)
	return nil
}

func main() {
	URL := "https://fr.wikipedia.org/wiki/Collaborateurs_de_l'Encyclopédie"
	prefixe := "https://fr.wikipedia.org"
	filePath := "HTML/Test0"

	// Utiliser une WaitGroup pour attendre la fin de la goroutine
	var wg sync.WaitGroup
	wg.Add(1)

	// Exécuter HTML2 en parallèle en tant que goroutine
	texte := HTML(filePath, URL, &wg)

	// Attendre la fin de la goroutine
	wg.Wait()

	liens := liens(URL, texte, prefixe)

	startTime := time.Now()

	// Utiliser une WaitGroup pour attendre la fin des goroutines
	var wgParallel sync.WaitGroup

	for i, lien := range liens {
		// Incrémente le compteur de la WaitGroup
		wgParallel.Add(1)
		go HTML(fmt.Sprintf("HTML/Test%d", i+1), lien, &wgParallel)
	}

	// Attendre la fin de toutes les goroutines
	wgParallel.Wait()

	elapsedTime := time.Since(startTime)
	fmt.Printf("Temps total d'exécution : %s\n", elapsedTime)

}
