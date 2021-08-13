using CSV: CSV
using DataFrames: DataFrame
using Downloads: download
using RegularExpressions: capture, CONSTANTS, of, one_of, not, pattern, raw, short
using Unzip: unzip

const DEFINITION = pattern(
    raw("**"),
    capture(of(:some, one_of(not, raw("*"))), name = "esperanto"),
    raw("**"),
    of(:maybe, short(:space)),
    of(
        :maybe,
        raw("\\["),
        capture(of(:some, one_of(not, raw("]"))), name = "comment"),
        raw("\\]"),
        short(:space),
    ),
    capture(of(:some, CONSTANTS.any), name = "english"),
)

function process_word(word)
    word[:english], word[:esperanto], something(word[:comment], "")
end

function download_and_parse(file)
    name = "akademia_vortaro"
    html = joinpath(file, string(name, ".html"))
    markdown = joinpath(file, string(name, ".md"))
    download("http://esperanto.davidgsimpson.com/librejo/avortaro.html", html)
    run(`pandoc $html -o $markdown`)
    unzip(
        Iterators.map(
            process_word,
            Iterators.filter(
                !isnothing,
                Iterators.map(
                    line -> match(DEFINITION, line),
                    split(read(markdown, String), "\\\n"),
                ),
            ),
        ),
    )
end

function write_dictionary(output)
    english, esperanto, comment = mktempdir(download_and_parse)
    CSV.write(
        output,
        DataFrame(english = english, esperanto = esperanto, comment = comment),
    )
end

write_dictionary("/home/brandon/Desktop/akademia_vortaro/akademia_vortaro.csv")
