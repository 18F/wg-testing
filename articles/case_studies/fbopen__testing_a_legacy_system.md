[WIP] FBOpen Legacy Testing
===

Even though FBOpen is only about two years old, it has gone through a couple of iterations since its inception, way back in the days of the 2013 round of the Presidential Innovation Fellows program. Back then, it was a quick, skunkworks-style project, and it was written with no automated tests. As the project matured into a publically-released API, it become more important to make sure regressions didn't creep in during development. To that end, we have employed some patterns and tricks in order to get some tests quickly working on the existing code base, even though it was not written with testing in mind.

Quick Integration Testing with Bash
==

FBOpen's loader scripts consist primarily of a series of Node utilities which accept streaming input via STDIN, and stream output via STDOUT. They are then glued together and run by a Bash script. Since they are normally run by a Bash script, it made sense to try and test the individual steps of the data munging process via Bash, too. With [assert.sh](https://github.com/lehmannro/assert.sh), I wrote a quick [setup script](https://github.com/18F/fbopen/blob/master/loaders/test/setup.sh) that I could `source` in any test file, and wrote [a number of shell scripts](https://github.com/18F/fbopen/tree/master/loaders/test) to test the steps of the FBOpen loader processes with our various datasets. `assert.sh` allows you to assert the output of any script command, and a few tricks helped along the way.

Golden File Testing
==

When I initially wrote these tests, I didn't know about the phrase [Golden File](https://pages.18f.gov/automated-testing-playbook/principles-practices-idioms/#avoid-golden-files) testing, but that's essentially what many of these tests are. Given input `File A`, assert that we get file `Output A`. Golden Files are mentioned in our [Automated Testing Playbook](https://pages.18f.gov/automated-testing-playbook/) as an anti-pattern, _except in the case of legacy systems_ such as this one.

Once the various test scripts were in place, I rolled them all into a [single-file test suite](https://github.com/18F/fbopen/blob/cloud_foundry/loaders/test/test_all.sh) so that I could call them in one command. No automatic script detection here, this is a bare-bones test suite, after all.
