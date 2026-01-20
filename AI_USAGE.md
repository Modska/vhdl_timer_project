In this file i will be detailling my journey for this project, i'm writing without any help from AI so sorry in advance for any spelling mistakes.

First of all, I want to begin with the fact that, this production method was not the way i'm used to work with vhdl. I only used Quartus Prime as the IDE with modelSim to simulate my code and the maXimator dev board as the FPGA.
To begin this project i asked gemeni how could I setup vscode in order to do this project and also the file structure including the Vunit part, 
as I was used of creating projects in Quartus prime and it handled the file structure alone. All of what gemeni proposed seemed logical so I went along with it

After that i began work in the timer.vhd file, I used the provided code to setup the variables, and used Gemini to write the first version of timer. I verified the correctness of this code,
in a old school way, as i was taught when i started programing in 2017, with pen and paper. 
I rewrote the main part of code and tested with values the first clock and last in order to see how the timer acts, if we were missing a clock or the time was wrong. 
That was useful because gemeni used variable that was not needed because of the code logic so i removed it.
That's when i started updating this github. With the code working in paper.

As I have 0 experience with VUnit i asked gemeni to write the tb_timer.vhd in order to test the code. In this step i asked to also configure the CI pipeline in github because that was a first time for me. 
On a personnal note i have to say i learned about a feature in github that's really usefull. It also generated the run.py code to run the tests.
With this i did some back forth with gemini because of implementation issues (versions or libs missing).

Then i hit my first major stop, the tests were never passed. So i asked claude to help me decipher what gemeni wrote in the test file helped me to pass the first basic test. 
But then i wanted to add more edge cases i hit another road block, with the code doing infinite simulation.
I started debugging this code with the help of AI but it could not solve the issue. So the day after I started to check in details the tb_timer.vhd file and the run.py file.

Bingo I found the issue, the simulation was waiting for a signal that would never change. From this varius issues i started to know my code and to know how VUnit works so i would not hit another block like this.
With the help of AI I added more edge cases but this I had fewer issues because I knew what wanted and understood the code in the logical aspect.
After some debuging with the help of AI that explained to me the various error messages and failed passed tests. I finnaly made it trough all the tests. 

Finnaly I have never done PSL in coding, I took my working code with the instruction and put it in claude in order to help me to setup and do this task.
It helped me do the base but i had issues with GHDL and the other useful libs (not finding it or wrong versions), i made again back and forth with ai to help me solve the issues.
In the end it worked as intended. I also asked the AI to create the readMe file to follow the instruction given. I verified it had wrote all the assumption and limitation encountered.
I also asked him to write the comments in english to make sure the code is clear and understable.

Throughout this project i verified the correctness using my logic and knowledge, and i sought in youtube videos or blogs things gave AI me that i wasn't sure.
