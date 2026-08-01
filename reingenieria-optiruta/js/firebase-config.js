// ─── OPTIRUTA Web — Firebase Configuration ───────────────────
// Firebase JS SDK v9+ (modular)

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import { getStorage } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-storage.js";

const firebaseConfig = {
  apiKey:            "AIzaSyC3Xuq2i1YKOeGauD1zkKvHNetE432GPIg",
  authDomain:        "optiruta-7bf9f.firebaseapp.com",
  projectId:         "optiruta-7bf9f",
  storageBucket:     "optiruta-7bf9f.firebasestorage.app",
  messagingSenderId: "964647743537",
  appId:             "1:964647743537:web:26e962002f45ba568f2510",
  measurementId:     "G-QL1VZQ13Q9"
};

const app     = initializeApp(firebaseConfig);
const auth    = getAuth(app);
const db      = getFirestore(app);
const storage = getStorage(app);

export { app, auth, db, storage };
