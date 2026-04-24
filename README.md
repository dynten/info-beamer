Portrait Info-beamer Package
=============================

https://dynten.net/j26/J26-Signage-System.zip

=============================



Beskrivning
-----------
Detta paket är en grund för att köra digital signage på stående (portrait) skärmar med info-beamer på en Raspberry Pi 3.

Funktioner
---------
- Stöd för stående 9:16-upplösning (default 1080x1920)
- Bakgrundsbild eller färg bakom alla fält
- Fälttyper: bild, bildspel (slideshow), video, text (laddas från fil)
- Overlay: rullande text (ticker) som ligger ovanpå allt annat
- Enkel konfigurerbar layout i `node.lua`

Filstruktur (exempel)
---------------------
- node.lua              — Huvudfil för paketet (layout + logik)
- package.json          — Paketmetainfo (pekare till option.json)
- option.json           — UI-inställningar (existerar i repot)
- background.jpg        — Bakgrundsbild (valfritt)
- font.ttf              — Valfri font för text (fallback försöks)
- slide1.jpg, slide2.jpg — Bildspelsexempel
- promo.mp4             — Videofil för video-fält
- ticker.txt            — Textfil för initial rulltext

Konfiguration
-------------
Redigera layout-tabellen i `node.lua` för att ändra fältens position och innehåll. Varje fält använder relativa koordinater (0..1) i form av `{ x, y, w, h }`.

Exempel:

- `{ x=0.05, y=0.05, w=0.9, h=0.35 }` — en zon nära toppen av skärmen

Ticker / rulltext
-----------------
Rulltexten läser från `ticker.txt` vid start. Du kan också uppdatera texten i realtid genom att skicka ett `node.event("data", "ny text")` till noden.

Tips för deployment
-------------------
- Placera alla resurser (bilder, video, font, ticker.txt) i paketets mapp på info-beamer-enheten.
- Anpassa `gl.setup(...)` i `node.lua` om du har annan fysisk upplösning.
- Se till att videofiler använder codecs som stöds av din Raspberry Pi och info-beamer.

Framtida förbättringar
---------------------
- Stöd för dynamisk layout via JSON-konfiguration
- Mer robust videotillståndshantering (pause/seek)
- Semi-transparent bakgrundsplatta bakom ticker istället för text-skyggning

Kontakt
-------
Detta är en startpunkt — hör av dig om du vill att jag implementerar vidare anpassningar.
