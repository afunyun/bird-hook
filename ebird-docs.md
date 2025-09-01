# This is just ripped straight from https://documenter.getpostman.com/view/664302/S1ENwy59 the ebird API docs for convenience.

## Authorization
All requests require an API key.

Header format:
```http
X-eBirdApiToken: {{x-ebirdapitoken}}
````

---

## Taxonomic Groups

**Endpoint:**

```
GET https://api.ebird.org/v2/ref/sppgroup/{speciesGrouping}
```

**URL Parameters:**

* `speciesGrouping`: `"merlin"` or `"ebird"`

  * `merlin`: Groups similar birds together (e.g., Falcons near Hawks).
  * `ebird`: Strict taxonomic order.

**Query Parameters:**

* `groupNameLocale`: One of
  `bg, cs, da, de, en, es, es_AR, es_CL, es_CU, es_ES, es_MX, es_PA, fr, he, is, nl, no, pt_BR, pt_PT, ru, sr, th, tr, zh`

  * Default: `en`
  * Locale for species group names (falls back to English if not available).

**Example Request:**

```bash
curl --location 'https://api.ebird.org/v2/ref/sppgroup/merlin' \
--header 'X-eBirdApiToken: {{x-ebirdapitoken}}'
```

**Example Response:**

```json
[
  {
    "groupName": "Waterfowl",
    "groupOrder": 1,
    "taxonOrderBounds": [[211, 579]]
  },
  {
    "groupName": "Cormorants and Anhingas",
    "groupOrder": 2,
    "taxonOrderBounds": [[1968, 2063]]
  },
  {
    "groupName": "Wattle-eyes and Batises",
    "groupOrder": 114,
    "taxonOrderBounds": [[16549, 16613]]
  }
]
```

---

## Region Info

**Endpoint:**

```
GET https://api.ebird.org/v2/ref/region/info/{regionCode}
```

**URL Parameters:**

* `regionCode`: A region code (major region, country, subnational1, subnational2, or locId).

**Query Parameters:**

* `regionNameFormat`: Controls how names are displayed.

  * `detailed` → `Madison County, New York, US`
  * `detailednoqual` → `Madison, New York`
  * `full` → `Madison, New York, United States`
  * `namequal` → `Madison County`
  * `nameonly` → `Madison`
  * `revdetailed` → `US, New York, Madison County`
* `delim`: Separator characters (default: `", "`).

**Example Request:**

```bash
curl --location 'https://api.ebird.org/v2/ref/region/info/CA-BC-GV?regionNameFormat=detailed' \
--header 'X-eBirdApiToken: {{x-ebirdapitoken}}'
```

**Example Response:**

```json
{
  "bounds": {
    "minX": -123.432442,
    "maxX": -122.408264,
    "minY": 49.001183,
    "maxY": 49.57455
  },
  "result": "Metro Vancouver District, British Columbia, CA",
  "code": "CA-BC-GV",
  "type": "subnational2",
  "parent": {
    "result": "British Columbia, CA",
    "code": "CA-BC",
    "type": "subnational1",
    "parent": {
      "result": "Canada",
      "code": "CA",
      "type": "country",
      "longitude": 0,
      "latitude": 0
    },
    "longitude": 0,
    "latitude": 0
  },
  "longitude": -122.920353,
  "latitude": 49.2878665
}
```

---

## Sub Region List

**Endpoint:**

```
GET https://api.ebird.org/v2/ref/region/list/{regionType}/{parentRegionCode}
```

**URL Parameters:**

* `regionType`: `"country"`, `"subnational1"`, `"subnational2"`
* `parentRegionCode`: Country or subnational1 code, or `"world"`

**Query Parameters:**

* `fmt`: `"json"` (default) or `"csv"`

**Notes:**

* You can fetch all `subnational1` or `subnational2` regions for a country.
* `regionType=country` is only valid with `world` as the parent region.

---

## notes:

* Always include `X-eBirdApiToken` in headers.
* Use `/ref/sppgroup/{speciesGrouping}` for species groupings (Merlin vs eBird order).
* Use `/ref/region/info/{regionCode}` for detailed region information.
* Use `/ref/region/list/{regionType}/{parentRegionCode}` to drill into subregions.

