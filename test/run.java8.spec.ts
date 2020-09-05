import * as chai from 'chai';

import * as worker from '../src/tasks/run';
import { IJob, IJobResult } from '../src/types';

const java8_code = `
import java.util.*;

class Main {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        String input = scanner.nextLine();
        System.out.println("Hello " + input);
    }
}
`;

describe('Test Java 8 code execution', () => {
  it('should print "Hello world" to stdout', async () => {
    const job: IJob = {
      id: 7,
      lang: 'java8',
      source: Buffer.from(java8_code).toString('base64'),
      stdin: Buffer.from('world').toString('base64')
    };

    const output: IJobResult = (await worker(job)).output;
    chai.assert.equal(output.stdout, 'Hello world\n');
    chai.expect(output.exec_time).satisfies(time => parseFloat(time) >= 0.00);
  });
});
