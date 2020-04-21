import CLIMiniZinc from 'minizinc/build/CLIMiniZinc'
import * as fs from 'fs'

export default function solve(
    ranks: number[],
    tonjeIndex?: number,
    haraldIndex?: number
) {
    const m = new CLIMiniZinc()

    const model = fs.readFileSync('../teamsorting.mzn', 'utf8')

    m.solve(
        { model, solver: 'cbc' },
        {
            playerRanks: ranks,
            players: [], // not used
            tonjeIndex: 15,
            haraldIndex: 18,
        }
    ).then((result) => {
        const output = result.solutions[0].extraOutput
        return JSON.parse(output.split('\n').slice(1).join('\n'))
    })
}
