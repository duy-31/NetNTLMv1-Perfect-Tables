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

## 📝 Credits & Research
The original data and research were provided by **Mandiant (Google Cloud)**. This project builds upon their work to make these tables more accessible for security auditors.
- **Reference:** [Mandiant Blog: Net-NTLMv1 Deprecation](https://cloud.google.com/blog/topics/threat-intelligence/net-ntlmv1-deprecation-rainbow-tables)
- **Data:** [Google Research](https://console.cloud.google.com/storage/browser/net-ntlmv1-tables)
- **Engine:** [jtesta/rainbowcrackalack](https://github.com/jtesta/rainbowcrackalack) (Original GPU & rt2rtc)
- **Logic:** [blurbdust/rainbowcrackalack](https://github.com/blurbdust/rainbowcrackalack) (NTLMv1 Support)

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

---

## 🔍 Usage Example
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
<center><img width="2048" height="1463" alt="image" src="https://github.com/user-attachments/assets/161b314f-3a6b-439f-a0db-f9e0e2cfe5ca" />
<img width="800" height="731" alt="image" src="https://github.com/user-attachments/assets/2a698749-a021-4de0-950d-0a6fcdd023ba" /></center>

---

## 🧲 Torrent & Community Seeding
The full dataset is massive. I am hosting a **Public Torrent** of the compacted `.rtc` files. 

**Magnet Link:** `magnet:?xt=urn:btih:TO_BE_ANNONCE&dn=NetNTLMv1_Perfect_RTC`

> [!IMPORTANT]
> **A Call to Action:** I will seed this for as long as possible, but **I need the community to help.** If you have spare storage (NAS/Servers) and high bandwidth, please keep this torrent active. The more people seed, the faster and more permanent this resource becomes for everyone.

---
## ⚖️ Responsibilities & Disclaimer
By using this project, you agree to use it only for authorized security auditing. The authors assume no liability for misuse or illegal activities.
