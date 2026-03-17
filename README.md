Unity workshop Android App:
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

1) What is this project?

This project is an Android app built using the Flutter framework.

The app allows users to create a new account and log in using Firebase Authentication. Users can sign up either as a student or an instructor. It also includes a forgot password feature, so users can reset their password if needed.

Instructors can create new courses and manage students within each course, including updating attendance and tracking how much progress each student has made.

Students can browse available courses and register or unregister for them easily.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------2) Tools and dependencies used:

a) Flutter framework(Dart programming language):
Flutter 3.35.7 and Dart 3.9.2

b) IDE(Integrated development environment) used:
VS CODE(Microsoft Visual Studio).

c)Android Studio(Android emulator)

d) Integrated firebase into the project:
For authentication and database management.

e) Flutter official packages used:
  a) device_preview => Test mobile app on different mobile screens
  b) get_x: => transiting between screens (with animation)
  c) firebase_core => connects flutter app to firebase.
  d) firebase_auth => user authentication (login/signup).
  e)cloud_firestore => flutter database.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------v
3)  Setup:

  a) Install VS Code
  b) Install flutter(recommened to use : Flutter 3.35.7 and Dart 3.9.2).
download and install flutter from official website: https://docs.flutter.dev/install/archive?utm_source
(Recommended to put the downloaded flutter folder in c/Flutter)
 c) Windows environment variable
    i)  Open "system environment variables" in windows  
    ii) Then click "Advanced tab" 
    iii) Then "Environment variables" button(at the bottom)
    iv) Then go to "System variables" at the bottom then click on "Path"
    v) Click "New" Button
     vi) Paste the the exact path for bin folder for the flutter folder(that we did download earlier).
     For example: C:\flutter\bin
    (So VS code can detect where flutter SDK is located)

d) Restart your computer

e) Open cmd(Command Line) and write: Flutter --version
TO check if flutter has been installed successfully on your device


d) download and Install Android Studio: this is android emulator so you can know how the mobile app looks like on your pc.

   i)  download android studio: https://developer.android.com/studio
   ii) Open android studio and go to "SDK manager" and then to SDK Tools, and click on the checkbox for "Android studio command line tools" and press "OK" button.
   iii) Go to "Virtual device manager" in android studio and install a suitable virtual device to test the flutter android app.


e) Running the flutter App:
Now everything is installed and ready, now time to test the flutter app.
  i) Go to: file tab => Open folder (Now open the project for flutter app)
  ii) go to far bottom-right and select the device emulator(then one we did just install using Android studio Virtual device manager) 
  iii) you can run the flutter app either by: going to the tabs at top an clicking the three dots ( ... ) then run then start debugging(also Run without debugging can work) OR go to the terminal at the bottom(if it didn't show up, go to view tab and click on "Terminal" button) and run the command "Flutter run"
 iv) you can build an apk file for android device using 'Flutter Build apk"

NOTE; if you had any issue running the app, the you go to the terminal and do
 1) Flutter clean
  2) Flutter pub get
  3) flutter run(you want to run it on your computer) OR flutter build apk(Build apk file for mobile device)


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

4) Instructions:
After you have the apk file and you ran the mobile application on your android device.

 a) For a first time user you need to create a new account. it can either be an account for a student or an instructor/teacher.
  (Just fill in the data and make sure it is valid and make a new account0

b) If you forgot you password, you can send a link your email to your account to reset your password(Just go to "Forgot Password" in the first page and fill your email). NOTE: The email might be in "Spam"

c) Then login and make sure to fill in the correct email and password(it is authenticated by firebase)

d) Logging as a student,
you can look through the different courses and click on one, then you can register/unregister a course.
You can register only if seats are available and also you can see your attendance in percentage and how much have been progressed in the course.

e) Logging as a Teacher.
   i) you can add a new course by clicking the blue " + " button.
and then fill in info about the new course and the milestones/classes that will be taken.

 ii) you can go to each course(by clicking on one).
   and you can see all the students that have joined the course. you can see all their info such as their name,email and phone number and all courses they have joined.
and you can give go to each milestone/class and choose wither or not the student have attended that specific class.

To understand attendance more:
  the attendance you choose in the instructor page is shown in student page as a Percentage.
   it basically calculate how many classes the students have attended from total and calculated in percentage.


iv) After choosing a course, you can modify the milestones/classes.
  When an instructor create a class the first time, the number of milestones and what are they called have already been chosen
  BUT here you can edit it later such as:

   Adding more milestones, removing some of them and edit their names.
   
   Also, you can choose wither or not a milestone/class have been done. and this is used to calculate how much of the course have been progressed.

   In student account, this is shown when tracking the progress in percentage


           

    



     



