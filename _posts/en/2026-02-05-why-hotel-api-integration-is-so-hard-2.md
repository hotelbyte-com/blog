---
layout: post
title: "Why Hotel API Integration is So Hard? (2) Data Chaos: Same Hotel, 5 Different Data Formats"
date: 2026-02-05 05:30:00 +0000
lang: en
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, data-normalization, room-mapping]
author: "HotelByte Team"
description: "The second nightmare of hotel API integration: data chaos. 5 suppliers, 5 different data formats - JSON/XML, nested structures, room names, price calculations... Have you written 50+ if/else statements?"
reading_time: "12 minutes"
---

> This is part 2 of the "Why Hotel API Integration is So Hard?" series.
> 
> [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/) | [Part 3: Rate Limiting Nightmare](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/) (Coming Soon)

---

## Have You Written 50+ if/else Statements to Handle Data Formats?

### Real Scenario

Let's say you're searching for a hotel in London:

**User Request**:
```json
{
  "hotel_id": "LON123",
  "check_in": "2026-02-10",
  "check_out": "2026-02-12",
  "guests": 2
}
```

**You call 5 supplier APIs and get 5 different response formats**:

#### Supplier A (Simple)
```json
{
  "hotel_id": "LON123",
  "hotel_name": "London Central Hotel",
  "rooms": [
    {
      "room_id": "R101",
      "room_name": "King Room",
      "price": 150.00,
      "currency": "GBP",
      "tax_included": true
    }
  ]
}
```

#### Supplier B (Nested Structure)
```json
{
  "property": {
    "code": "LON123",
    "name": "London Central Hotel"
  },
  "room_rates": [
    {
      "rate_plan_code": "R101",
      "description": "King Room",
      "rates": {
        "amount": 135.00,
        "currency": "USD",
        "tax_exclusive": true,
        "tax_amount": 27.00
      }
    }
  ]
}
```

#### Supplier C (XML Format)
```xml
<hotels>
  <hotel code="LON123" name="London Central Hotel">
    <rooms>
      <room type="101" name="King Room">
        <price currency="EUR">162.50</price>
        <taxes included="true"/>
      </room>
    </rooms>
  </hotel>
</hotels>
```

#### Supplier D (Complex Nested)
```json
{
  "results": {
    "hotels": [
      {
        "hotel": {
          "identifiers": [
            {"type": "internal", "value": "LON123"}
          ],
          "information": {
            "name": "London Central Hotel"
          }
        },
        "availability": {
          "rooms": [
            {
              "room": {
                "id": "101",
                "details": {
                  "name": "King Room",
                  "bed_type": "KING",
                  "square_meters": 25
                }
              },
              "pricing": {
                "base_rate": 150.00,
                "taxes": 30.00,
                "total_rate": 180.00,
                "currency": "USD",
                "tax_inclusive": true
              }
            }
          ]
        }
      }
    ]
  }
}
```

#### Supplier E (Most Complex)
```json
{
  "search_response": {
    "hotels": [
      {
        "hotel_code": "LON123",
        "hotel_name": "London Central Hotel",
        "rooms": [
          {
            "room_code": "101",
            "room_name": "King Room",
            "rates": [
              {
                "rate_id": "RATE1",
                "price_per_night": 160.00,
                "currency": "GBP",
                "tax": {
                  "vat": 20.00,
                  "city_tax": 5.00,
                  "included_in_price": true
                },
                "fees": {
                  "service_fee": 10.00,
                  "included": false
                }
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### The Problem

**For the same room type "King Room", you got**:

| Supplier | Price | Currency | Taxes | Total |
|----------|--------|----------|-------|-------|
| A | 150.00 | GBP | Included | 150.00 |
| B | 135.00 | USD | Not included | 162.00 |
| C | 162.50 | EUR | Included | 162.50 |
| D | 180.00 | USD | Included | 180.00 |
| E | 160.00 | GBP | Included + service fee | 175.00 |

**How do you tell users the "cheapest price"?**

1. Currency conversion (GBP/USD/EUR)
2. Unify tax calculation (included vs not included)
3. Handle service fees
4. Sort

**How many lines of code did you write?**

---

## Pain Point 1: Same Room, 5 Different Names

### Real Scenario

User searches for "King Room", 5 suppliers return:

| Supplier | Room Name |
|----------|-----------|
| A | King Room |
| B | Deluxe King - City View |
| C | King Bed City View |
| D | King City View Room |
| E | Superior King Room |

### How Do You Match?

**Method 1: String Matching (Simple but Unreliable)**
```python
def match_rooms(user_query, supplier_rooms):
    matches = []
    for room in supplier_rooms:
        if user_query.lower() in room.name.lower():
            matches.append(room)
    return matches
```

**Problems**:
- ❌ "King Room" vs "Deluxe King" - match?
- ❌ "King Room with City View" vs "King Room" - same?
- ❌ "Superior King Room" - what is this?

**Method 2: Keyword Extraction (Slightly Better)**
```python
def extract_keywords(room_name):
    keywords = []
    # Extract bed type
    if "king" in room_name.lower():
        keywords.append("king")
    # Extract view
    if "city" in room_name.lower():
        keywords.append("city_view")
    # Extract class
    if "deluxe" in room_name.lower():
        keywords.append("deluxe")
    if "superior" in room_name.lower():
        keywords.append("superior")
    return keywords

def match_rooms_by_keywords(user_keywords, supplier_rooms):
    matches = []
    for room in supplier_rooms:
        room_keywords = extract_keywords(room.name)
        if set(user_keywords) <= set(room_keywords):
            matches.append(room)
    return matches
```

**Problems**:
- ⚠️ Depends on rules, need to maintain many rules
- ⚠️ Synonym issues: "City View" vs "Urban View" vs "Metropolis View"
- ⚠️ Context missing: "Deluxe King" - Deluxe is class or description?

### Pits We've Encountered

**Pit 1: User Complaints "Room Doesn't Match Picture"**

- User sees: "Deluxe King - City View"
- Picture shows: King Bed + City View
- Actual check-in: King Bed (ordinary) + City View (ordinary window)

**Reason**: Supplier A's "Deluxe King" = Ordinary King Bed + City View
- Supplier B's "Deluxe King" = Deluxe King Bed + City View
- Supplier C's "Deluxe King" = King Bed + Deluxe Room + City View

**User Complaint**: "Picture shows Deluxe King, but I only got ordinary King!"

**Pit 2: Price Mapping Error**

User booked "Deluxe King - City View" ($180),
Actually checked in "King City View" ($150).

**User Complaint**: "I booked $180 room, why only got $150?"

**Reason**: String matching misjudged room type.

---

## Pain Point 2: Price Calculation, 5 Different Logics

### The Nightmare of Price Formats

| Supplier | Format | Tax Included? | Service Fee? |
|----------|--------|--------------|--------------|
| A | 150.00 GBP | Yes | Included in price |
| B | 135.00 USD + 27.00 USD tax | No | None |
| C | 162.50 EUR | Yes | Additional 5 EUR cleaning fee |
| D | 150.00 base + 30.00 tax | No | Additional 10% service fee |
| E | 160.00 GBP + 20.00 VAT + 5.00 city tax | Yes | Additional 10.00 GBP |

### How Do You Calculate Total Price?

**Step 1: Unify Currency**
```python
# Currency conversion (assume 1 USD = 0.80 GBP = 0.90 EUR)
exchange_rates = {
    "GBP": 1.0,
    "USD": 0.80,
    "EUR": 0.89
}

def convert_to_gbp(amount, currency):
    return amount * exchange_rates[currency]
```

**Step 2: Unify Taxes**
```python
def calculate_total_price(room, nights):
    # Case A: Tax included
    if room.tax_included:
        base = room.price
    # Case B: Tax not included
    else:
        base = room.price + room.tax_amount
    
    # Case C: Additional service fee
    if room.service_fee and not room.service_fee_included:
        base += room.service_fee
    
    return base * nights
```

**Step 3: Handle Exceptions**

- **Supplier C**: Additional 5 EUR cleaning fee (per night)
- **Supplier D**: Additional 10% service fee (total price)
- **Supplier E**: VAT (20%) + city_tax (5%)

**Problems**:
- ❌ Supplier documentation doesn't clearly state "additional fees"
- ❌ Some fees are "may be charged", not "must be charged"
- ❌ Some fees are "pay at front desk", not "online payment"

### Real Pits

**Pit 1: Price Mismatch**

- Displayed: $150/night
- Actual paid: $180/night (+ $20 city tax + $10 service fee)

**User Complaint**: "Why did the price change?"

**Reason**: Supplier documentation says "tax included", but doesn't mention "city tax and service fee not included".

**Pit 2: Exchange Rate Issues**

- User searches: 1 USD = 0.80 GBP
- User books: 1 USD = 0.82 GBP
- Actual paid: 2.5% more than displayed

**User Complaint**: "Price is wrong!"

---

## Pain Point 3: Inventory Status, 5 Different Meanings

### What is "Available"?

| Supplier | Available Status | Meaning |
|----------|-----------------|---------|
| A | "Available" | Has rooms, can book |
| B | "Available" | Has rooms, needs confirmation |
| C | "OnRequest" | Has rooms, needs 24h confirmation |
| D | "Available" | Has rooms, but may be oversold |
| E | "Available" | Has rooms, but has minimum stay |

### User Confusion

- User sees: "Available"
- User places order: "Confirming..."
- Supplier replies: "Sorry, no rooms"

**User Complaint**: "It clearly showed available, why no rooms?"

### The Nightmare of Inventory Types

| Supplier | Inventory Type | How to Handle |
|----------|---------------|---------------|
| A | Real-time inventory | Immediately confirm |
| B | 24h confirmation | Submit and wait for confirmation |
| C | OnRequest | Submit and wait 24-48h |
| D | Oversold risk | May confirm fail |
| E | Minimum stay | Must stay X nights to book |

### Real Pits

**Pit 1: OnRequest Confirmation Failed**

- User books OnRequest room
- Wait 24h
- Supplier replies: "Sorry, no rooms"
- User already arranged trip, now find new hotel

**User Complaint**: "You wasted my 24h!"

**Pit 2: Oversold Risk**

- Displayed: "Available"
- User books
- Supplier replies: "Sorry, oversold"
- User Complaint: "Why didn't you tell me there's risk?"

**Pit 3: Minimum Stay**

- User wants to stay 1 night
- Displayed: "Available"
- User books
- Supplier replies: "Minimum 3 nights"
- User Complaint: "Why didn't you tell me earlier?"

---

## Pain Point 4: Timezone Chaos

### 3 Timezones, Do You Understand?

| Timezone | Usage | Example |
|----------|--------|---------|
| UTC | API data transmission | "2026-02-10T00:00:00Z" |
| HotelLocal | Hotel local time | "2026-02-10T12:00:00+01:00" (London winter time) |
| UserLocal | User local time | "2026-02-10T08:00:00-03:00" (New York) |

### Real Scenario

**User searches**:
- User time: 2026-02-10 (New York time)
- Hotel location: London
- Check-in time: Local time 2月10日14:00

**Supplier A returns**:
```json
{
  "check_in": "2026-02-10T00:00:00Z",  // UTC
  "check_out": "2026-02-12T00:00:00Z"  // UTC
}
```

**Supplier B returns**:
```json
{
  "check_in": "2026-02-10T12:00:00+01:00",  // HotelLocal (London)
  "check_out": "2026-02-12T12:00:00+01:00"  // HotelLocal (London)
}
```

**Supplier C returns**:
```json
{
  "check_in": "2026-02-10T08:00:00-03:00",  // UserLocal (New York)
  "check_out": "2026-02-12T08:00:00-03:00"  // UserLocal (New York)
}
```

### The Problems

1. Are these 3 times the same?
   - UTC: 2026-02-10 00:00
   - HotelLocal: 2026-02-10 12:00 (London)
   - UserLocal: 2026-02-10 08:00 (New York)

2. How to handle?
   - Convert all to UTC?
   - Convert all to HotelLocal?
   - Convert all to UserLocal?

3. What about daylight saving time / winter time switch?
   - 2026年3月28日, London switches to daylight time
   - 2月10日 and 3月10日, 1 hour difference

### Real Pits

**Pit 1: User Booked Yesterday's Hotel**

- User chooses: 2月10日 check-in
- System converts: UTC 2月9日 24:00
- Supplier understands: 2月9日 check-in
- User Complaint: "I booked tomorrow, why is it yesterday?"

**Reason**: Timezone conversion error (UTC vs HotelLocal)

**Pit 2: Wrong Price**

- Displayed: $150/night
- Actual: $165/night
- User Complaint: "Why is the price wrong?"

**Reason**:
- 2月10日: Winter time, $150/night
- 3月10日: Daylight time, $165/night (peak season price adjustment)
- User thought it's same time, actually 1 hour + 1 month difference

---

## Our Solution

### Core Idea: Standardization

**Problem**: 5 suppliers, 5 different data formats

**Solution**: Unified standardization layer

```
Supplier A → Standardization Layer → Unified Data Model
Supplier B → Standardization Layer → Unified Data Model
Supplier C → Standardization Layer → Unified Data Model
Supplier D → Standardization Layer → Unified Data Model
Supplier E → Standardization Layer → Unified Data Model
```

### Unified Data Model

```yaml
Hotel:
  id: string
  name: string
  location: 
    latitude: float
    longitude: float
    timezone: string

Room:
  id: string
  hotel_id: string
  name: string
  bed_type: enum(KING, QUEEN, TWIN, SINGLE, etc.)
  area: int  # square meters
  amenities: [string]

RatePlan:
  id: string
  room_id: string
  name: string
  base_price: float
  currency: string
  tax_included: boolean
  tax_amount: float
  service_fee: float
  fees: [Fee]

Inventory:
  rate_plan_id: string
  check_in: date  # UTC
  check_out: date  # UTC
  availability: enum(AVAILABLE, ON_REQUEST, SOLD_OUT)
  confirmation_required: boolean
  min_nights: int
```

### Standardization Process

```
1. Receive supplier raw data
   ↓
2. Parse data format (JSON/XML)
   ↓
3. Extract key fields (hotel_id, room_id, price, etc.)
   ↓
4. Convert to unified data model
   ↓
5. Validate data integrity
   ↓
6. Return standardized data
```

### Room Mapping: GIATA + AI

**GIATA (Global Hotel Information Database)**:
- Global hotel room type authority standard
- 500,000+ hotels, 1,000,000+ room types
- Standardized room type names and attributes

**AI Room Mapping**:
- Vectorize room names and descriptions
- Similarity matching (cosine similarity)
- Attribute supplementation (bed type, area, facilities)

**Flow**:
```
1. Supplier room → GIATA query
   ↓
2. GIATA returns standardized room type
   ↓
3. If GIATA has no match → AI matching
   ↓
4. AI returns similar room type (85%+ accuracy)
   ↓
5. Manual review (optional)
   ↓
6. Establish mapping relationship
```

**Accuracy**:
- GIATA direct match: 92%
- AI matching: 85%
- After manual review: 95%+

### Price Standardization

```python
# Standardize price
def normalize_price(raw_price, supplier):
    # 1. Convert to unified currency (GBP)
    gbp_price = convert_to_gbp(raw_price.amount, raw_price.currency)
    
    # 2. Handle taxes
    if raw_price.tax_included:
        net_price = gbp_price
    else:
        net_price = gbp_price + raw_price.tax_amount
    
    # 3. Handle service fees
    if raw_price.service_fee and not raw_price.service_fee_included:
        net_price += raw_price.service_fee
    
    # 4. Handle other fees
    for fee in raw_price.fees:
        if not fee.included:
            net_price += fee.amount
    
    return {
        "currency": "GBP",
        "net_price": net_price,
        "tax_included": True,
        "fees_included": True
    }
```

### Inventory Status Standardization

| Supplier Status | Standardized Status | Meaning |
|---------------|-------------------|---------|
| Available | AVAILABLE | Has rooms, can book |
| OnRequest | ON_REQUEST | Has rooms, needs 24-48h confirmation |
| SoldOut | SOLD_OUT | No rooms |
| Limited | AVAILABLE | Has rooms, but limited quantity |

**Special Handling**:
- Oversold risk: Mark as AVAILABLE, but add risk warning
- Minimum stay: Add min_nights field
- Peak season restrictions: Add availability_notes field

### Timezone Standardization

```python
from datetime import datetime, timezone
import pytz

# Standardize datetime
def normalize_datetime(raw_datetime, hotel_timezone):
    # 1. Parse raw time (may have timezone)
    if isinstance(raw_datetime, str):
        dt = datetime.fromisoformat(raw_datetime)
        if dt.tzinfo is None:
            # No timezone, assume UTC
            dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = raw_datetime
    
    # 2. Convert to hotel timezone
    hotel_tz = pytz.timezone(hotel_timezone)
    hotel_local_time = dt.astimezone(hotel_tz)
    
    # 3. Extract date (ignore time)
    hotel_date = hotel_local_time.date()
    
    # 4. Return UTC time (standardized)
    utc_time = hotel_local_time.astimezone(timezone.utc)
    
    return {
        "date": hotel_date,
        "utc_datetime": utc_time,
        "hotel_timezone": hotel_timezone
    }
```

---

## Our Advantages

### 1. One API, All Suppliers

**Before**: Integrate 5 suppliers → 5 APIs → 5 data formats
**Now**: Integrate HotelByte → 1 API → Unified data model

### 2. Standardized Data Model

- Hotel/Room/RatePlan/Inventory
- Unified room type names and attributes
- Unified price calculation (tax included)
- Unified inventory status
- Unified timezone handling

### 3. AI Room Mapping

- GIATA authority database
- AI similarity matching
- 95%+ accuracy

### 4. Comprehensive Documentation and SDK

- API docs: openapi.hotelbyte.com
- Go SDK: github.com/hotelbyte-com/sdk-go
- Java SDK: github.com/hotelbyte-com/sdk-java
- Code examples and best practices

---

## Call to Action

### Are You Still Writing 50+ if/else Statements?

**Problems**:
- Same hotel, 5 suppliers, 5 data formats
- Same room, 5 different names
- Same price, 5 different calculation logics
- How many lines of code did you write?

**Our Solution**:
- Unified data model (Hotel/Room/RatePlan/Inventory)
- AI room mapping (95%+ accuracy)
- Price standardization (automatically calculate total)
- Timezone standardization (automatically convert)

**You Only Need**:
```go
import "github.com/hotelbyte-com/sdk-go/hotelbyte"

client := hotelbyte.NewClient("YOUR_API_KEY")

// Search hotels
result, err := client.SearchHotels(&hotelbyte.SearchRequest{
    Destination: "London",
    CheckIn:     time.Date(2026, 2, 10, 0, 0, 0, 0, time.UTC),
    CheckOut:    time.Date(2026, 2, 12, 0, 0, 0, 0, time.UTC),
    Guests:      2,
})

// Return unified data model
for _, hotel := range result.Hotels {
    for _, room := range hotel.Rooms {
        fmt.Printf("%s: %s - $%.2f\n",
            hotel.Name,
            room.Name,
            room.TotalPrice,  // Already standardized
        )
    }
}
```

**No 50+ if/else. No 5 data formats. Only unified data model.**

---

## Next Steps

### Free Trial

- 30 days free trial
- No credit card required
- Start testing immediately

**[Free Trial for 30 Days](https://waitlist.hotelbyte.com)**

### View Documentation

- API docs: [openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- SDK docs: [docs.hotelbyte.com](https://docs.hotelbyte.com)
- Best practices: [blog.hotelbyte.com](https://blog.hotelbyte.com)

### Contact Us

Have questions? Contact our engineers directly.

**[Contact Us](mailto:support@hotelbyte.com)**

---

## Series Navigation

- [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/)
- [Part 2: Data Chaos (This Article)](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/)
- [Part 3: Rate Limiting Nightmare (Coming Soon)](#)

---

**Next article preview: Rate Limiting Nightmare - Your search feature got blocked 3 times on day 1**

---

*Reading time: ~12 minutes*
*Difficulty: Medium (requires understanding API integration, data standardization)*
