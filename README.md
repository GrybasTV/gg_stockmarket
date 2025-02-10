
# RedM Stock Market System

**Version:** 1.0.0  
**Author:** GrybasTv

## Overview
GG Stock Market is a comprehensive stock trading system for RedM, integrated with VORP framework. It provides players with a dynamic, interactive stock market experience.

## Features
- Real-time stock price updates
- Buy and sell stocks through intuitive UI
- Multiple stock options (TECH, ENERGY, FINANCE)
- Responsive design
- Language support (Lithuanian, English)

## Dependencies
- VORP Core
- VORP Inventory
- VORP Menu
- MySQL Async

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

