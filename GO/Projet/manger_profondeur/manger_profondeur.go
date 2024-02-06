package manger_profondeur

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strconv"
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
		fmt.Printf("Une erreur s'est produite pour écrire : %s\n", err)
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

func manger(URL string, prefixe string, nomDossier string, wgProf *sync.WaitGroup) {

	defer wgProf.Done()

	/*chiffre := nomDossier[:4]
	temps, _ := strconv.Atoi(chiffre)
	time.Sleep(time.Duration(temps*2) * time.Second)*/

	chiffre := nomDossier[:4]
	temps, _ := strconv.Atoi(chiffre)
	time.Sleep(time.Duration(temps*2) * time.Second)

	filePath := fmt.Sprintf("%s/Page0", nomDossier)

	if _, err := os.Stat(nomDossier); os.IsNotExist(err) {
		// Créer le dossier avec les permissions 0755 (permissions standard)
		_ = os.Mkdir(nomDossier, 0755)
	}

	// Utiliser une WaitGroup pour attendre la fin de la goroutine
	var wg sync.WaitGroup
	wg.Add(1)

	// Exécuter HTML2 en parallèle en tant que goroutine
	texte := HTML(filePath, URL, &wg)

	// Attendre la fin de la goroutine
	wg.Wait()

	liens := liens(URL, texte, prefixe)

	// Utiliser une WaitGroup pour attendre la fin des goroutines
	var wgConcu sync.WaitGroup

	for i, lien := range liens {
		// Incrémente le compteur de la WaitGroup
		wgConcu.Add(1)
		go HTML(fmt.Sprintf("%s/Page%d", nomDossier, i+1), lien, &wgConcu)
	}

	// Attendre la fin de toutes les goroutines
	wgConcu.Wait()
}

func manger_profond(URL string, nombre int) {

	//si l'url vaut a, on prend l'url par défaut
	if URL == "a" {
		URL = "https://fr.wikipedia.org/wiki/Collaborateurs_de_l'Encyclopédie"
	}

	// on récupère le préfixe de l'url
	urlSplit := strings.Split(URL, "/")
	prefixe := urlSplit[0] + "//" + urlSplit[2]

	filePath := "HTML0/Page0"

	nomDossier := "HTML0"

	if _, err := os.Stat(nomDossier); os.IsNotExist(err) {
		// Créer le dossier avec les permissions 0755 (permissions standard)
		_ = os.Mkdir(nomDossier, 0755)
	}

	// Utiliser une WaitGroup pour attendre la fin de la goroutine
	var wg sync.WaitGroup
	wg.Add(1)

	// Exécuter HTML2 en parallèle en tant que goroutine
	texte := HTML(filePath, URL, &wg)

	// Attendre la fin de la goroutine
	wg.Wait()

	liens := liens(URL, texte, prefixe)

	startTime := time.Now()

	var wgDepart sync.WaitGroup
	wgDepart.Add(1)
	manger(URL, prefixe, nomDossier, &wgDepart)
	wgDepart.Wait()

	var wgManger sync.WaitGroup

	nbDossier := 1
	for i := 50; i <= 54; i++ {
		wgManger.Add(1)
		nomDossier := fmt.Sprintf("HTML%d", nbDossier)
		nbDossier += 1
		fmt.Println(nomDossier)
		go manger(liens[i], prefixe, nomDossier, &wgManger)
	}
	wgManger.Wait()

	elapsedTime := time.Since(startTime)
	fmt.Printf("Temps total d'exécution : %s\n", elapsedTime)
}
