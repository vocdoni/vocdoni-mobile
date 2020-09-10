const glob = require("glob")
const fs = require("fs")

function main() {
    const srcFiles = glob.sync(__dirname + "/../lib/**/*.dart")
    const langFiles = glob.sync(__dirname + "/../assets/i18n/*.json")
    const baseLang = require(langFiles[0])

    for (let path of srcFiles) {
        let items = path.split("/")
        let filename = items[items.length - 1]
        let content = fs.readFileSync(path).toString()

        for (let originalTxt of Object.keys(baseLang)) {
            while (content.indexOf('"' + originalTxt + '"') >= 0) {
                const newKey = getKeFromText(originalTxt)
                content = content.replace('"' + originalTxt + '"', '"main.' + newKey + '"')

                console.log(`[${filename}] Replacing "${originalTxt}" as "main.${newKey}"`)
            }
            while (content.indexOf("'" + originalTxt + "'") >= 0) {
                const newKey = getKeFromText(originalTxt)
                content = content.replace("'" + originalTxt + "'", '"main.' + newKey + '"')

                console.log(`[${filename}] Replacing "${originalTxt}" as "main.${newKey}"`)
            }
        }
        fs.writeFileSync(path, content)
    }

    // JSON files
    for (let path of langFiles) {
        let items = path.split("/")
        let filename = items[items.length - 1]
        let content = fs.readFileSync(path).toString()

        for (let originalTxt of Object.keys(baseLang)) {
            if (content.indexOf('"' + originalTxt + '"') < 0) continue

            const newKey = getKeFromText(originalTxt)
            content = content.replace('"' + originalTxt + '":', '"main.' + newKey + '":')

            console.log(`[${filename}] Replacing "${originalTxt}" as "main.${newKey}"`)
        }
        fs.writeFileSync(path, content)
    }
}

function getKeFromText(str) {
    const words = str.toLowerCase()
        .replace(/[^a-zA-Z0-9 ]+/g, "")
        .split(" ")
        .filter(str => !!str)

    for (let i = 1; i < words.length; i++) {
        words[i] = words[i][0].toUpperCase() + words[i].substr(1)
    }
    return words.join("")
}

main()
