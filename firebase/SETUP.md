# Firebase setup for Foundit (Android)

Do these once. The app also runs without them in local mode (data on the phone only).

1. **Create a project** at console.firebase.google.com (Spark plan, no card needed).
2. **Add an Android app.** Package name `com.onavri.foundit`. Add the debug SHA-1
   `A7:3D:6A:7E:8F:2B:84:ED:1B:37:F9:33:35:56:20:2F:C6:AB:A4:96`. Download `google-services.json`.
3. **Authentication, Sign-in method:** turn on Email/Password and Anonymous (guest browsing).
   Google can wait for the next step.
4. **Firestore Database:** create it in production mode, then open the Rules tab and paste in
   `firebase/firestore.rules`, then Publish.
5. **GitHub secret:** in the repo go to Settings, Secrets and variables, Actions, New repository
   secret. Name `GOOGLE_SERVICES_JSON`, value = the whole contents of `google-services.json`.
6. Push any change (or run the workflow by hand). The build detects the secret and switches the
   app from local mode to Firebase.
7. **Make yourself campus admin:** sign up in the app, open Firestore, Data, `users`, your
   document, and change `role` from `user` to `admin`.

Do not commit `google-services.json`; it is in `.gitignore`.
