import CLIMiniZinc from 'minizinc/build/CLIMiniZinc';
import { IResult, EStatus, IStatistics } from 'minizinc/build';
import * as fs from 'fs';
import * as path from 'path';

interface Result {
    status: EStatus;
    complete: boolean;
    output: object;
    statistics?: IStatistics;
}

export default function solve(ranks: number[], preference?: number[]) {

    // const modelPath = path.join(__dirname, 'teamsorting.mzn');
    const modelPath = path.resolve(__dirname, 'teamsorting.mzn')
    const model = fs.readFileSync(modelPath, 'utf8');

    const minizinc = new CLIMiniZinc();

    return minizinc
        .solve(
            { model, solver: 'cbc' },
            {
                playerRanks: ranks,
                players: ranks.map(toString), // only needed when getting output in Minizinc IDE
                preference: preference ? preference : ranks.map(() => 0),
            }
        )
        .then((result: IResult) => {
            // console.log(result);
            const output = result.solutions[0].extraOutput;
            const json = JSON.parse(output.split('\n').slice(1).join('\n'));
            return {
                status: result.status,
                output: output ? json : {},
                complete: result.complete,
            };
        });
}
