# ⚡ NetNTLMv1-Perfect-Tables (Indices 0-4096) ⚡

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Status: Active Seeding](https://img.shields.io/badge/Status-Seeding_In_Progress-blue.svg)

## 🎯 Project Goal
This repository provides a high-performance PowerShell pipeline to transform the raw **NetNTLMv1 Rainbow Tables** (released by **Mandiant**) into an optimized, "Perfect" **Compact (.rtc)** format. 

By converting the original `.rt` files, we achieve:
* **~40% Reduction in Disk Space** (Crucial for a multi-TB dataset).
* **0% Chain Collisions:** Using the `-p` (Perfect) flag ensures every chain is unique.
* **Instant Compatibility:** Pre-sorted and ready for `crackalack_lookup` without further processing.

---

# Mandiant Net-NTLMv1 Rainbow Tables (RT Format)

This repository (or torrent) provides a reformatted version of the Rainbow Tables released by **Mandiant (Google Cloud)**. The original dataset was published to accelerate the deprecation of the Net-NTLMv1 protocol by making hash collisions easily demonstrable for security professionals.

## 📄 License & Attribution

The work of Mandiant (Google Cloud) is licensed under the **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

* **Original Author:** Mandiant (Google Cloud).
* **Original Source:** `gs://net-ntlmv1-tables/`.
* **Official License Link:** [https://storage.googleapis.com/net-ntlmv1-tables/LICENSE](https://storage.googleapis.com/net-ntlmv1-tables/LICENSE).
* **Full License Terms:** [Creative Commons CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

> **Note on Redistributions:** Under the CC BY 4.0 license, you are free to share, copy, and redistribute the material in any medium or format, and to adapt, remix, or build upon the material for any purpose, provided you give appropriate credit.

---

## 📝 Credits & Research
The original data and research were provided by **Mandiant (Google Cloud)**. This project builds upon their work to make these tables more accessible for security auditors.
- **Reference:** [Mandiant Blog: Net-NTLMv1 Deprecation](https://cloud.google.com/blog/topics/threat-intelligence/net-ntlmv1-deprecation-rainbow-tables)
- **Data:** [Google Research](https://console.cloud.google.com/storage/browser/net-ntlmv1-tables)
- **Engine:** [jtesta/rainbowcrackalack](https://github.com/jtesta/rainbowcrackalack) (Original GPU)
- **Logic:** [blurbdust/rainbowcrackalack](https://github.com/blurbdust/rainbowcrackalack) (NTLMv1 Support)
- **Implementation:** [Project-rainbowcrack](http://project-rainbowcrack.com) ( rtsort & rt2rtc)

---

## 🛠 Technical Specifications
- **Type:** NetNTLMv1 (DES-based)
- **Charset:** `byte#7-7`
- **Chain Length:** 134,217,668
- **RTC Parameters:** `-s 32 -e 48 -p`
- **Software:** Optimized for RainbowCrack 1.8+

---

## ⚙️ Pipeline Flow I've Done (rtc-pipeline.ps1)
1. **Download:** Pulls `.rt` from Mandiant G-Storage.
2. **Sort:** Runs `rtsort.exe` to index endpoints.
3. **Compact:** `rt2rtc -s 32 -e 48 -p` (Removes duplicates).
4. **Clean:** Moves `.rtc` to final storage, deletes `.rt` source.

- uncompress everything so that look like this:
<img width="1207" height="195" alt="image" src="https://github.com/user-attachments/assets/8af5849c-4246-44d3-b6ab-f6e6d17910fc" />

- edit the file rtc-pipline.ps1 and change all the need paths
<img width="953" height="192" alt="image" src="https://github.com/user-attachments/assets/c76712c2-b3bc-44cd-a4e9-f35533af718c" />

- run the rtc-pipline.ps1 and wait (a long time!) make sure you have enough space!
<center><img width="712" height="476" alt="image" src="https://github.com/user-attachments/assets/d8e27326-c369-4e9f-add5-806517330e6f" /></center>

---

## 🔍 Usage Example of the RTC rainbow tables (crack the same CT2 given by Mandiant)
```powershell
.\crackalack_lookup.exe .\rtc a9d83c6ca210be62
```
---

## 🚀 How to Use 
1. **Download:** Get the files via the Magnet link.
2. **Setup:** Place all `.rtc` files in a folder (FOLDER value).
3. **Crack:** Run `crackalack_lookup` against your captured hash (CT1 or CT2 value):
   ```powershell
   .\crackalack_lookup.exe FOLDER CT1 (or CT2)
   ```
<center><img width="1024" height="731" alt="image" src="https://github.com/user-attachments/assets/161b314f-3a6b-439f-a0db-f9e0e2cfe5ca" /></center>

---

## 📺 Demo
  
https://github.com/user-attachments/assets/c2c5f152-1a87-480a-a98b-644531d11251

---

## 🧲 Torrent & Community Seeding
The full dataset is massive. I am hosting a **Public Torrent** of the compacted `.rtc` files. 

**Magnet Link:** `magnet:?xt=urn:btih:TO_BE_ANNONCE&dn=NetNTLMv1_Perfect_RTC`

> [!IMPORTANT]
> **A Call to Action:** I will seed this for as long as possible, but **I need the community to help.** If you have spare storage (NAS/Servers) and high bandwidth, please keep this torrent active. The more people seed, the faster and more permanent this resource becomes for everyone.
> **"A Rainbow Table is only as strong as its Seeding Swarm."** > If you find this data useful for your audits, please **Give Back by Seeding.**

---

## 📊 Progress Tracking
Current status of the conversion and seeding:
- [x] Index 0-1000 (Processing...) ⏳ 
- [x] Index 1001-2000 - Seeding 🚀 [Download Set (Magnet Link)](magnet:?xt=urn:btih:31731bd4fb93a1771b1a300b20ee87bc951b9a63&dn=1001-2000&xl=1341075609150&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.theoks.net%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.moeking.me%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.armun.net%3A6969%2Fannounce&tr=https%3A%2F%2Ftracker.nanoha.org%3A443%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce)
- [x] Index 2001-3000 (Processing...) ⏳ 
- [ ] Index 3001-4096 (Pending)
      
---
## ⚖️ Responsibilities & Disclaimer
By using this project, you agree to use it only for authorized security auditing. The authors assume no liability for misuse or illegal activities.


