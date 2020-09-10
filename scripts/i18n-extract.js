const glob = require("glob")
const fs = require("fs")

const dqRegExp = /getText[\s]*\([\s]*[a-zA-Z_]+[a-zA-Z0-9_]*,[\s]*"[^"\\]*(?:\\.[^"\\]*)*"\)/gm
const sqRegExp = /getText[\s]*\([\s]*[a-zA-Z_]+[a-zA-Z0-9_]*,[\s]*'[^'\\]*(?:\\.[^'\\]*)*'\)/gm
const tqRegExp = /getText[\s]*\([\s]*[a-zA-Z_]+[a-zA-Z0-9_]*,[\s]*"""[^"]*(?:(?:"?"?)[^"])*"""\)/gm

const languages = ["en", "fr", "es", "ca", "eo", "eu", "nb", "zh"]
const defaultLanguage = languages[0]

function main() {
    const files = glob.sync(__dirname + "/../lib/**/*.dart")
    const strings = files.reduce((prev, cur) => prev.concat(processFile(cur)), [])

    const uniqueStrings = sortUnique(strings)
    const stringsTemplate = {}

    uniqueStrings.forEach(txt => {
        stringsTemplate[txt] = txt
    })

    languages.forEach(lang => {
        const targetFile = `${__dirname}/../assets/i18n/${lang}.json`

        var existingStrings = {}
        if (fs.existsSync(targetFile)) {
            existingStrings = JSON.parse(fs.readFileSync(targetFile).toString())
        }

        // merge
        const newStrings = {}
        for (var k in stringsTemplate) {
            if (typeof existingStrings[k] == "string") {
                if (existingStrings[k].trim().length > 0) {
                    newStrings[k] = existingStrings[k]  // keep current
                    continue
                }
            }
            newStrings[k] = ""
        }
        fs.writeFileSync(targetFile, JSON.stringify(newStrings, null, 2))
    })

    console.log("Extracted", Object.keys(stringsTemplate).length, "strings for", languages)
}

function processFile(path) {
    const text = fs.readFileSync(path).toString()
    var dqMatches = text.match(dqRegExp) || []
    dqMatches = dqMatches.map(txt => {
        txt = txt.replace(/^getText[\s]*\([\s]*[a-zA-Z_]+[a-zA-Z0-9_]*,[\s]*"/, "")
            .replace(/\\n/g, "\n")
            .replace(/\\r/g, "\r")
            .replace(/\\t/g, "\t")
        return txt.slice(0, txt.length - 2)
    })
    var sqMatches = text.match(sqRegExp) || []
    sqMatches = sqMatches.map(txt => {
        txt = txt.replace(/^getText[\s]*\([\s]*[a-zA-Z_]+[a-zA-Z0-9_]*,[\s]*'/, "")
            .replace(/\\n/g, "\n")
            .replace(/\\r/g, "\r")
            .replace(/\\'/g, "'")
            .replace(/\\t/g, "\t")
        return txt.slice(0, txt.length - 2)
    })
    var tqMatches = text.match(tqRegExp) || []
    tqMatches = tqMatches.map(txt => {
        txt = txt.replace(/^getText[\s]*\([\s]*[a-zA-Z_]+[a-zA-Z0-9_]*,[\s]*"""/, "")
            .replace(/\\n/g, "\n")
            .replace(/\\r/g, "\r")
            .replace(/\\t/g, "\t")
        return txt.slice(0, txt.length - 4)
    })
    return dqMatches.concat(sqMatches).concat(tqMatches)
}

function sortUnique(arr) {
    if (arr.length === 0) return arr;
    arr = arr.sort((a, b) => a > b ? 1 : (a == b ? 0 : -1));
    const ret = [arr[0]];
    for (let i = 1; i < arr.length; i++) {
        if (arr[i - 1] !== arr[i]) {
            ret.push(arr[i]);
        }
    }
    return ret;
}


main()