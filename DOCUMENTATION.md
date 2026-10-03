# Campaign Tool Extension for Google Sheets

## Welcome!

Welcome to the Campaign Tool extension for Google Sheets, from **Doikait Mobilization Labs**!

The first release of this extension enables campaign coordinators to quickly identify which of 
the volunteers in their spreadsheet database reside within a given radius of a specific geographic location. 
The resulting filtered list can be used to support a variety of campaign goals—such as notifying matching volunteers 
of an upcoming event near them.

---

## How It Works

Your volunteer database is assumed to have **exactly one column** that contains the complete address of each volunteer.

> 💡 If you break out this information into subfields such as `'Street'`, `'City'`, `'State'`, etc., you must 
> create a new column that **concatenates** all of these items into one full address.

If your address column is named anything other than `'Address'`, the extension will prompt you for the exact column name.

The extension uses **straight-line distance** ("as the crow flies") to filter volunteers 
based on proximity to a reference location. It does not account for driving time, traffic, or route availability.

To enable this functionality, you must provide a valid **Google Maps API key**. 
A pop-up dialog will guide you through this setup the first time you attempt to use filtering.

> ⚠️ **Note:** Google offers a free usage tier, but API calls may incur charges beyond that threshold.  
> The extension caches lat/long information in hidden columns to avoid redundant re-computation.

---

### **What It Adds to Your Sheet**

Once configured, the extension enhances your active sheet by appending 
**four hidden columns** immediately to the right of your existing data:

1. **Latitude** – numerical latitude from the Maps API  
2. **Longitude** – numerical longitude from the Maps API  
3. **Address Hash** – a digital signature of the address, used to detect changes  
4. **Error Marker** – a red ❌ icon indicating addresses that failed lookup  

These columns are **automatically updated** prior to filtering runs when:
- A new address is entered
- An existing address is changed
- Lat/long data is missing for an existing row

You can reveal these columns at any time by selecting:  
**Campaign → Debug: Show Lat/Long**

This helps you identify problematic rows (e.g., invalid or partial addresses), copy/paste them into 
the **type-ahead address field**, and find a corrected format that yields a successful Maps lookup.


