---
layout: post
title: "Why Hotel API Integration Is So Hard? (6) Room Mapping: Same Room, 5 Different Names"
date: 2026-02-09 05:30:00 +0000
lang: en
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, room-mapping, giata]
author: "HotelByte Team"
description: "The sixth nightmare of hotel API integration: room mapping. 5 suppliers, 5 different room type names—King Room, Deluxe King, Superior King, Premium King... Is this the same room? Users complain that rooms don't match the photos."
reading_time: "18 minutes"
---

> This is Part 6 of the "Why Hotel API Integration Is So Hard?" series.
> 
> [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/) | 
> [Part 2: Data Chaos](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/) | 
> [Part 3: Rate Limiting Nightmare](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/) | 
> [Part 4: Error Handling](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/) | 
> [Part 5: Timezone Issues](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-5/) | 
> [Part 7: Summary (Coming Soon)](#)

---

## Have You Seen the Same Room with 5 Different Names?

### Real-World Scenario

**User searches for "King Room"**:

**Supplier A returns**:
```json
{
  "room_id": "R101",
  "room_name": "King Room",
  "bed_type": "King",
  "area": "25 m²",
  "amenities": ["WiFi", "TV", "Air conditioning"]
}
```

**Supplier B returns**:
```json
{
  "room_id": "DELUXE_KING",
  "room_name": "Deluxe King - City View",
  "bed_type": "King Bed",
  "area": "28 m²",
  "amenities": ["WiFi", "TV", "Air Conditioning", "City View"]
}
```

**Supplier C returns**:
```json
{
  "room_id": "KING_CITY",
  "room_name": "King Bed City View",
  "bed_type": "KING",
  "area": "26 m²",
  "amenities": ["Free WiFi", "Flat-screen TV", "Air Conditioning", "City View"]
}
```

**Supplier D returns**:
```json
{
  "room_id": "101",
  "room_name": "King City View Room",
  "bed_type": "King",
  "area": "25 m²",
  "amenities": ["WiFi", "Television", "Air Conditioning"]
}
```

**Supplier E returns**:
```json
{
  "room_id": "SUP_KING",
  "room_name": "Superior King Room",
  "bed_type": "King",
  "area": "27 m²",
  "amenities": ["Complimentary WiFi", "TV", "Climate Control", "City View"]
}
```

### Here's the Problem

**Is this the same room?**

- All have King Bed
- All have City View
- Similar area (25-28 m²)
- Similar amenities (WiFi, TV, Air Conditioning)

**But**:
- Different room names (5 types)
- Different room IDs (5 types)
- Different amenity descriptions

**How does the user choose?**

---

## Pain Point 1: String Matching Is Unreliable

### Real-World Scenario

**User searches for "King Room"**

**Your matching logic**:

```python
def match_rooms(user_query, supplier_rooms):
    matches = []
    for room in supplier_rooms:
        if user_query.lower() in room.name.lower():
            matches.append(room)
    return matches
```

**Results**:

| User Query | Room Name | Match? | Why? |
|-------------|-----------|--------|------|
| King Room | King Room | ✅ | Exact match |
| King Room | Deluxe King - City View | ❌ | "King" is there, but "Deluxe" is not in query |
| King Room | King Bed City View | ❌ | "King" is there, but "Bed" is not in query |
| King Room | King City View Room | ❌ | "King" is there, but has extra "City View" |
| King Room | Superior King Room | ❌ | "King" is there, but has extra "Superior" |

**Problem**:
- ❌ 5 suppliers' King Rooms, only 1 matches
- User only sees 1 option, should see 5

**Improvement**:

```python
def match_rooms_v2(user_query, supplier_rooms):
    matches = []
    for room in supplier_rooms:
        # Extract keywords
        room_keywords = extract_keywords(room.name)
        user_keywords = extract_keywords(user_query)
        
        # Check if contains user keywords
        if set(user_keywords) <= set(room_keywords):
            matches.append(room)
    
    return matches

def extract_keywords(room_name):
    keywords = []
    # Extract bed type
    if "king" in room_name.lower():
        keywords.append("king")
    elif "queen" in room_name.lower():
        keywords.append("queen")
    elif "twin" in room_name.lower():
        keywords.append("twin")
    
    # Extract view
    if "city" in room_name.lower():
        keywords.append("city_view")
    elif "sea" in room_name.lower():
        keywords.append("sea_view")
    elif "garden" in room_name.lower():
        keywords.append("garden_view")
    
    # Extract class
    if "deluxe" in room_name.lower():
        keywords.append("deluxe")
    elif "superior" in room_name.lower():
        keywords.append("superior")
    
    return keywords
```

**Results**:

| User Query | Room Name | Extracted Keywords | Match? |
|-------------|-----------|-------------------|--------|
| King Room | King Room | [king] | ✅ |
| King Room | Deluxe King - City View | [king, city_view, deluxe] | ❌ (extra deluxe and city_view) |
| King Room | King Bed City View | [king, city_view] | ❌ (extra city_view) |
| King Room | King City View Room | [king, city_view] | ❌ (extra city_view) |
| King Room | Superior King Room | [king, superior] | ❌ (extra superior) |

**Problem**:
- ⚠️ Still only 1 supplier matches
- ⚠️ Relies on rules, need to maintain many rules
- ⚠️ Synonym issues: "City View" vs "Urban View" vs "Metropolis View"

---

## Pain Point 2: Semantic Matching Is Difficult

### Real-World Scenario

**User searches for "Deluxe King Room"**

**Room types returned by suppliers**:

| Supplier | Room Name | Should Match? |
|----------|-----------|---------------|
| A | King Room | ❌ (No Deluxe) |
| B | Deluxe King - City View | ✅ |
| C | King Bed City View | ❌ (No Deluxe) |
| D | King City View Room | ❌ (No Deluxe) |
| E | Superior King Room | ⚠️ (Superior vs Deluxe, are they the same?) |

### Problem: Deluxe vs Superior vs Premium

**Deluxe means**:
- Better bed
- Larger area
- More amenities

**Superior means**:
- Better bed
- Larger area
- More amenities

**Premium means**:
- Better bed
- Larger area
- More amenities

**Problem**:
- Deluxe, Superior, Premium, are they the same?
- Or different tiers?
- If user searches for "Deluxe King", should "Superior King" match?

### Issues with Semantic Matching

**Method 1: Synonym Mapping**

```python
synonym_mapping = {
    "deluxe": ["superior", "premium", "executive"],
    "superior": ["deluxe", "premium", "executive"],
    "premium": ["deluxe", "superior", "executive"],
}

def match_with_synonyms(user_query, supplier_rooms):
    user_keywords = extract_keywords(user_query)
    expanded_keywords = []
    for kw in user_keywords:
        if kw in synonym_mapping:
            expanded_keywords.extend(synonym_mapping[kw])
        else:
            expanded_keywords.append(kw)
    
    matches = []
    for room in supplier_rooms:
        room_keywords = extract_keywords(room.name)
        if set(expanded_keywords) & set(room_keywords):
            matches.append(room)
    
    return matches
```

**Problem**:
- ⚠️ Relies on manually maintained synonym mapping
- ⚠️ Synonyms may not be accurate enough
- ⚠️ Different suppliers may have different synonyms

**Method 2: Word Vector Similarity**

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('all-MiniLM-L6-v2')

def match_with_embeddings(user_query, supplier_rooms):
    # 1. Convert user query to vector
    user_embedding = model.encode(user_query)
    
    matches = []
    for room in supplier_rooms:
        # 2. Convert room name to vector
        room_embedding = model.encode(room.name)
        
        # 3. Calculate cosine similarity
        similarity = cosine_similarity(user_embedding, room_embedding)
        
        # 4. If similarity > threshold, match
        if similarity > 0.8:
            matches.append(room)
    
    return matches
```

**Problem**:
- ⚠️ Requires training or loading pre-trained model
- ⚠️ Requires computing resources
- ⚠️ Similarity threshold needs tuning

---

## Pain Point 3: Incomplete Attributes

### Real-World Scenario

**User searches for "King Room with City View"**

**Supplier A returns**:
```json
{
  "room_name": "King Room",
  "bed_type": "King",
  "area": "25 m²",
  "amenities": ["WiFi", "TV", "Air conditioning"]
}
```

**Supplier B returns**:
```json
{
  "room_name": "Deluxe King - City View",
  "bed_type": "King",
  "area": "28 m²",
  "amenities": ["WiFi", "TV", "Air Conditioning", "City View"]
}
```

**Supplier C returns**:
```json
{
  "room_name": "King Bed City View",
  "bed_type": "KING",
  "area": "26 m²",
  "amenities": ["Free WiFi", "Flat-screen TV", "Air Conditioning", "City View"]
}
```

### Problem: Inconsistent Attributes

| Supplier | Has City View? | How Represented? |
|----------|----------------|-----------------|
| A | ❌ | None |
| B | ✅ | In amenities |
| C | ✅ | In amenities |
| D | ✅ | In room_name |
| E | ✅ | In room_name |

**Problem**:
- Some suppliers put City View in amenities
- Some suppliers put City View in room_name
- Some suppliers have no City View attribute at all

**User complaints**:
- "Why do some rooms have City View and some don't?"
- "I searched for King Room with City View, why do some results not have City View?"

---

## Pain Point 4: Price Mismatch

### Real-World Scenario

**User books "Deluxe King - City View" ($180)**

**Order confirmation**:
- Room type: Superior King Room (Supplier E)
- Price: $150

**User complains**:
- "I booked Deluxe King - City View ($180), why does the order show Superior King Room ($150)?"
- "The price is wrong too!"

**Cause**:
- Your matching logic thinks "Deluxe King - City View" and "Superior King Room" are the same room type
- Actually, these two room types are different (Deluxe vs Superior)
- Prices are also different ($180 vs $150)

### Problem: False Match

**Matching logic**:
```python
# Simple string matching
if "King" in room_name:
    return "King Room"  # All King matched to "King Room"
```

**Problem**:
- ❌ Deluxe King and Superior King both matched to "King Room"
- ❌ User thinks they booked Deluxe King, actually booked Superior King
- ❌ Price is wrong

---

## Pain Point 5: Users Complain Rooms Don't Match Photos

### Real-World Scenario

**User books "Deluxe King - City View"**

**Photo seen**:
- King Bed (Deluxe)
- City View (large window)
- 28 m² area

**Actual check-in**:
- King Bed (standard)
- City View (standard window)
- 25 m² area

**User complains**:
- "The photo shows Deluxe King, but I only got a standard King!"
- "Photo shows 28 m², actually only 25 m²!"
- "Photo shows large window, actually just a standard window!"

**Cause**:
- Supplier A's "Deluxe King" = Standard King Bed + City View
- Supplier B's "Deluxe King" = Deluxe King Bed + City View + 28 m²
- Supplier C's "Deluxe King" = King Bed + Deluxe Room + City View

**Problem**:
- Different suppliers define "Deluxe" differently
- Different suppliers define area differently (may include balcony)
- Different suppliers define view differently (may have different levels)

---

## How We Solve It

### Core Approach: GIATA + AI Room Mapping

**Problem**: 5 suppliers, 5 different room type names, incomplete attributes, prone to false matching.

**Solution**: GIATA authoritative database + AI room mapping + attribute supplementing + consistency verification

---

### 1. GIATA Authoritative Database

#### What Is GIATA?

- Global hotel information database
- 500,000+ hotels
- 1,000,000+ room types
- Standardized room type names and attributes
- Authoritative room mapping standard

#### GIATA Room Type Standards

| GIATA Room Type | Bed Type | Area | Amenities |
|-----------------|----------|------|-----------|
| STANDARD_KING | King | 20-25 m² | Basic amenities |
| DELUXE_KING | King | 25-30 m² | Basic + more |
| SUPERIOR_KING | King | 25-30 m² | Basic + more |
| PREMIUM_KING | King | 30-35 m² | Basic + most |
| EXECUTIVE_KING | King | 30-35 m² | Basic + most |

#### GIATA Query

```python
import giata

giata_client = giata.Client(api_key="YOUR_GIATA_API_KEY")

def query_giata(hotel_id, supplier_room_name):
    # 1. Query GIATA database
    result = giata_client.search(
        hotel_id=hotel_id,
        room_name=supplier_room_name
    )
    
    # 2. If found, return GIATA standard room type
    if result:
        return {
            "giata_room_type": result.room_type,  # "DELUXE_KING"
            "standard_name": result.standard_name,  # "Deluxe King Room"
            "bed_type": result.bed_type,  # "King"
            "area_min": result.area_min,  # 25
            "area_max": result.area_max,  # 30
            "amenities": result.amenities  # ["WiFi", "TV", "AC", "City View"]
        }
    
    # 3. If not found, use AI matching
    return match_with_ai(hotel_id, supplier_room_name)
```

---

### 2. AI Room Mapping

#### Word Vector Similarity

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('all-MiniLM-L6-v2')

def match_with_ai(hotel_id, supplier_room_name):
    # 1. Get all GIATA standard room types for this hotel
    giata_rooms = giata_client.get_standard_rooms(hotel_id)
    
    # 2. Convert supplier room type to vector
    supplier_embedding = model.encode(supplier_room_name)
    
    # 3. Calculate similarity with each GIATA standard room type
    similarities = []
    for giata_room in giata_rooms:
        giata_embedding = model.encode(giata_room.standard_name)
        similarity = cosine_similarity(supplier_embedding, giata_embedding)
        similarities.append((giata_room, similarity))
    
    # 4. Select GIATA room type with highest similarity
    sorted_similarities = sorted(similarities, key=lambda x: x[1], reverse=True)
    best_match = sorted_similarities[0]
    
    # 5. If similarity > threshold, return match result
    if best_match[1] > 0.85:
        return {
            "giata_room_type": best_match[0].room_type,
            "standard_name": best_match[0].standard_name,
            "confidence": best_match[1],  # 0.85-1.0
            "method": "ai_embedding"
        }
    
    # 6. If similarity not high enough, return low confidence result
    return {
        "giata_room_type": best_match[0].room_type,
        "standard_name": best_match[0].standard_name,
        "confidence": best_match[1],
        "method": "ai_embedding",
        "warning": "Low confidence, please review"
    }
```

#### Rule Engine (Auxiliary)

```python
def match_with_rules(supplier_room):
    # 1. Extract room type features
    bed_type = extract_bed_type(supplier_room.name)
    view_type = extract_view_type(supplier_room.name)
    room_class = extract_room_class(supplier_room.name)  # Deluxe/Superior/Premium
    
    # 2. Match GIATA room type based on features
    if bed_type == "King" and view_type == "City View":
        if room_class == "Deluxe":
            return "DELUXE_KING_CITY_VIEW"
        elif room_class == "Superior":
            return "SUPERIOR_KING_CITY_VIEW"
        elif room_class == "Premium":
            return "PREMIUM_KING_CITY_VIEW"
        else:
            return "KING_CITY_VIEW"
    
    # 3. Other rules...
    pass

def extract_bed_type(room_name):
    if "King" in room_name:
        return "King"
    elif "Queen" in room_name:
        return "Queen"
    elif "Twin" in room_name:
        return "Twin"
    else:
        return "Unknown"

def extract_view_type(room_name):
    if "City View" in room_name or "City" in room_name:
        return "City View"
    elif "Sea View" in room_name or "Sea" in room_name:
        return "Sea View"
    elif "Garden View" in room_name or "Garden" in room_name:
        return "Garden View"
    else:
        return "Unknown"

def extract_room_class(room_name):
    if "Deluxe" in room_name:
        return "Deluxe"
    elif "Superior" in room_name:
        return "Superior"
    elif "Premium" in room_name:
        return "Premium"
    elif "Executive" in room_name:
        return "Executive"
    else:
        return "Standard"
```

---

### 3. Attribute Supplementing

#### Supplement Missing Attributes

```python
def supplement_room_attributes(room, giata_room):
    # 1. If room has no bed type, supplement from GIATA
    if not room.bed_type:
        room.bed_type = giata_room.bed_type
    
    # 2. If room has no area, supplement from GIATA
    if not room.area:
        room.area = (giata_room.area_min + giata_room.area_max) / 2
    
    # 3. If room has no amenities, supplement from GIATA
    if not room.amenities:
        room.amenities = giata_room.amenities
    else:
        # Merge amenities
        room.amenities = list(set(room.amenities + giata_room.amenities))
    
    # 4. If room has no view, supplement from GIATA
    if not room.view:
        room.view = giata_room.view
    
    return room
```

---

### 4. Consistency Verification

#### Verify Room Mapping Accuracy

```python
def validate_room_mapping(supplier_room, giata_room):
    warnings = []
    
    # 1. Verify bed type consistency
    supplier_bed = extract_bed_type(supplier_room.name)
    if supplier_bed != giata_room.bed_type:
        warnings.append(f"Bed type mismatch: {supplier_bed} vs {giata_room.bed_type}")
    
    # 2. Verify area consistency
    if supplier_room.area and giata_room.area_min:
        if supplier_room.area < giata_room.area_min * 0.9 or \
           supplier_room.area > giata_room.area_max * 1.1:
            warnings.append(f"Area mismatch: {supplier_room.area} vs {giata_room.area_min}-{giata_room.area_max}")
    
    # 3. Verify amenities consistency
    supplier_amenities = set(supplier_room.amenities)
    giata_amenities = set(giata_room.amenities)
    intersection = supplier_amenities & giata_amenities
    if len(intersection) / len(giata_amenities) < 0.7:
        warnings.append(f"Amenities mismatch: {len(intersection)}/{len(giata_amenities)}")
    
    # 4. Return verification result
    return {
        "is_valid": len(warnings) == 0,
        "warnings": warnings
    }
```

---

### 5. Manual Review (Optional)

#### Low Confidence Mappings Require Manual Review

```python
def review_low_confidence_mappings():
    # 1. Query low confidence mappings (confidence < 0.85)
    low_confidence_mappings = database.query(
        "SELECT * FROM room_mappings WHERE confidence < 0.85 AND reviewed = false"
    )
    
    # 2. Manual review
    for mapping in low_confidence_mappings:
        # Display to reviewer
        display_mapping_for_review(mapping)
        
        # Wait for review result
        review_result = wait_for_review(mapping.id)
        
        if review_result.approved:
            # Approved, update mapping
            database.update(
                "UPDATE room_mappings SET reviewed = true, confidence = 1.0 WHERE id = ?",
                mapping.id
            )
        else:
            # Rejected, delete mapping
            database.delete(
                "DELETE FROM room_mappings WHERE id = ?",
                mapping.id
            )
```

---

## Our Advantages

### 1. GIATA Authoritative Database

- 500,000+ hotels
- 1,000,000+ room types
- Standardized room type names and attributes
- Authoritative room mapping standard

### 2. AI Room Mapping

- Word vector similarity
- 85%+ accuracy
- Automatic matching, no manual intervention needed

### 3. Rule Engine (Auxiliary)

- Rule-based matching
- Improves accuracy
- Handles edge cases

### 4. Attribute Supplementing

- Automatically supplements missing attributes
- Unifies room type information
- Improves user experience

### 5. Consistency Verification

- Automatically verifies mapping accuracy
- Identifies incorrect mappings
- Low confidence mappings manually reviewed

---

## Call to Action

### Have You Seen the Same Room with 5 Different Names?

**Problems**:
- 5 suppliers, 5 different room type names
- Incomplete attributes (some suppliers missing bed type, area, amenities)
- Semantic matching difficulties (Deluxe vs Superior vs Premium)
- Price mismatch (false matching causes)
- Users complain rooms don't match photos

**Our Solution**:
- GIATA authoritative database (standardized room type names and attributes)
- AI room mapping (word vector similarity, 85%+ accuracy)
- Attribute supplementing (automatically supplements missing attributes)
- Consistency verification (automatically verifies mapping accuracy)
- Manual review (low confidence mappings)

**You only need**:
```go
import "github.com/hotelbyte-com/sdk-go/hotelbyte"

client := hotelbyte.NewClient("YOUR_API_KEY")

// Search hotels (automatically handles room mapping)
result, err := client.SearchHotels(&hotelbyte.SearchRequest{
    Destination: "London",
    CheckIn:     time.Date(2026, 2, 10, 0, 0, 0, 0, time.UTC),
    CheckOut:    time.Date(2026, 2, 12, 0, 0, 0, 0, time.UTC),
    Guests:      2,
})

// We automatically handle:
// - GIATA authoritative database query
// - AI room mapping
// - Attribute supplementing
// - Consistency verification

for _, hotel := range result.Hotels {
    for _, room := range hotel.Rooms {
        fmt.Printf("%s: $%.2f\n", room.Name, room.TotalPrice)
    }
}
```

**No room type name chaos. No false matching. Only accurate room mapping.**

---

## Next Steps

### Free Trial

- 30-day free trial
- No credit card required
- Start testing immediately

**[Start Your 30-Day Free Trial](https://waitlist.hotelbyte.com)**

### View Documentation

- API documentation: [openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- SDK documentation: [docs.hotelbyte.com](https://docs.hotelbyte.com)
- Best practices: [blog.hotelbyte.com](https://blog.hotelbyte.com)

### Contact Us

Have questions? Contact our engineers directly.

**[Contact Us](mailto:support@hotelbyte.com)**

---

## Series Navigation

- [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/)
- [Part 2: Data Chaos](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/)
- [Part 3: Rate Limiting Nightmare](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/)
- [Part 4: Error Handling](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/)
- [Part 5: Timezone Issues](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-5/)
- [Part 6: Room Mapping (This Article)](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-6/)
- [Part 7: Summary (Coming Soon)](#)

---

**Next up: Summary - Why Can We Solve These Problems?**

---

*Reading time: ~18 minutes*
*Difficulty: Medium (requires understanding of room type mapping, GIATA, AI similarity)*
