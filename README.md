TechUSB Creator (Linux)
=====================
Version: 1.0<br/>
Tested on Ruby version 1.9.3
<br/><br/>
<h3>Purpose</h3>
<p>This is a Linux version of TechUSB Creator, an application designed to create a bootable version of RepairTech's TechUSB. This project was developed by Aaron Atamian, a computer engineering student at California Polytechnic University, San Luis Obispo, and an intern at RepairTech. We decided to open-source it in order to encourage future development and improvements.</p>
<h3>What is TechUSB?</h3>
<p>TechUSB is a bootable computer repair utility that automates your hardware diagnostic and virus removal process in a bootable environment. It is designed specifically for IT Professionals. More info about TechUSB and TechSuite can be found on RepairTech's website. NOTE: You still have to have a valid license for TechUSB to use it.</p>
<b><a href="https://repairtechsolutions.com/tour/techusb">Learn More About TechUSB</a></b>
<h3>How to Use</h3>
<p> <b>Check Dependencies:</b><br/>
Ruby<br/>
Green Shoes (command to install: gem install green_shoes)<br>
Unetbootin (command to install: apt-get install unetbootin)<br/>
7-Zip (command to install: apt-get install 7zip-full)<br/><br/>

After doing so, type 'sudo ruby main.rb'. After launch, you will be required to enter your authentication key and the email address associated with it. This application allows you to put custom ISOs onto TechUSB that can be selected upon bootup. Additionally, the utility provides the option to format the USB drive that TechUSB will be copied to (This is not required, but it is recommended). To begin the process of creating TechUSB, simply click "Download & Install." This will download the required files (roughly 830MB) and put them onto the selected drive. You will be notified when the process is finished.</p>
<h3>Feedback/Questions</h3>
<p> Submit any questions or suggestions to us via <a href="mailto:support@repairtechsolutions.com">email</a>.</p>
<br/><br/>
