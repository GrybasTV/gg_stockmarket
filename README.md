
# RedM Stock Market System

**Version:** 1.0.0  
**Author:** GrybasTv

Support: https://discord.gg/KxSBTYr5wS

## Overview
The RedM Stock Market System introduces a virtual stock market to your RedM server, providing players with an opportunity to trade financial assets while enhancing the roleplay experience. This system integrates seamlessly with the **VORP Core Framework** and supports essential gameplay mechanics, including money sinks and dynamic economic interactions.

---

## Key Features

1. **Money Sink Opportunity**  
   - Players spend in-game money on each trade, offering a sustainable way to reduce overall server currency inflation.

2. **Educational Purpose**  
   - The system educates players on how financial markets operate, the flow of money in investment schemes, and introduces them to the fundamentals of financial "pyramids."

3. **Enhanced Roleplay**  
   - Players can generate excitement (hype) around certain stocks, creating opportunities for profits. Much like in real life with Bitcoin or similar markets, profits are possible only when supply remains limited.

---

## Highlights
- **Dynamic Market Pricing:** Prices increase or decrease with every transaction, simulating supply and demand.
- **Profit Opportunities:** Players who strategically trade and time their decisions can earn significant profits if the market conditions align.  
- **Realistic Failures:** Players can experience losses, especially if overselling crashes the market.
- **Roleplay-Driven Economy:** Introduces immersive scenarios for financial interactions, player collaboration, and market manipulation.

---

## Requirements
- **VORP Core Framework**  
  Get it here: [VORP Core GitHub](https://github.com/orgs/VORPCORE/repositories)  
- **VORP Inventory** and **VORP Menu** dependencies for inventory and menu interactions.

---

## Installation

1. **Download and Install**  
   Place this script into your server's `resources` folder.

2. **Configuration**  
   Edit the `config.lua` file to tailor the system to your server:
   - Set the default language (`en` or `lt`).
   - Define the trading location coordinates and blip settings.
   - Adjust stock options, pricing, and other market dynamics.

3. **Add to Server Start**  
   Add the following line to your server's `server.cfg`:
   ```plaintext
   ensure stockmarket
   ```

---

## How It Works
1. Players visit the specified stock market location on the map.
2. By pressing **[G]**, they open the trading menu.
3. Players can buy or sell available stocks, which affects market prices dynamically.

---

## Configuration

### Localization
You can modify translations in `config.lua`. Example:
```lua
Config.Translations = {
    en = {
        buySuccess = "You bought %d x %s for $%.2f",
    },
    lt = {
        buySuccess = "Pirkote %d x %s už $%.2f",
    }
}
```

### Stock Parameters
Each stock in `Config.Stocks` can have custom settings, such as:
- **Initial Price**  
- **Price Changes (Increase/Decrease)**  
- **Minimum Price Threshold**

---

## Key Gameplay Benefits

### Money Sink
This system ensures players consistently spend money, reducing overall server inflation. Each trade incurs a cost, helping stabilize the economy.

### Education
Players learn the basics of financial markets:
- How money flows in investment schemes.
- The risks and rewards of buying and selling assets.

### Roleplay and Hype
The stock market creates exciting roleplay opportunities:
- Players can collaborate to manipulate the market.
- Profit-making through strategy and timing, especially in scenarios mimicking real-world assets like Bitcoin.

---

## Troubleshooting
1. Ensure all dependencies (`vorp_core`, `vorp_inventory`, `vorp_menu`) are installed and working.
2. Check your console for error messages if something isn’t working as expected.

---

## Useful Links
- [VORP Core Documentation](https://vorpcore.github.io/VORP_Documentation/)
- [RedM Script Forum](https://forum.cfx.re/c/redm-development/54)
- [RDR3 Natives](https://rdr3natives.com)

---

