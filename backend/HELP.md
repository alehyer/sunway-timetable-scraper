# Getting Started

### Reference Documentation

For further reference, please consider the following sections:

* [Official Apache Maven documentation](https://maven.apache.org/guides/index.html)
* [Spring Boot Maven Plugin Reference Guide](https://docs.spring.io/spring-boot/4.1.0/maven-plugin)
* [Create an OCI image](https://docs.spring.io/spring-boot/4.1.0/maven-plugin/build-image.html)
* [Spring Web](https://docs.spring.io/spring-boot/4.1.0/reference/web/servlet.html)
* [Spring Web Services](https://docs.spring.io/spring-boot/4.1.0/reference/io/webservices.html)

### Guides

The following guides illustrate how to use some features concretely:

* [Building a RESTful Web Service](https://spring.io/guides/gs/rest-service/)
* [Serving Web Content with Spring MVC](https://spring.io/guides/gs/serving-web-content/)
* [Building REST services with Spring](https://spring.io/guides/tutorials/rest/)
* [Producing a SOAP web service](https://spring.io/guides/gs/producing-web-service/)

### Maven Parent overrides

Due to Maven's design, elements are inherited from the parent POM to the project POM.
While most of the inheritance is fine, it also inherits unwanted elements like `<license>` and `<developers>` from the
parent.
To prevent this, the project POM contains empty overrides for these elements.
If you manually switch to a different parent and actually want the inheritance, you need to remove those overrides.




I’ll inspect the Spring Boot project docs and key source files, then summarize what each file does and what must be configured before calling any endpoint.

I’ve got the core startup, API, and AI/scraping code; next I’ll inspect the DTOs so I can explain the request/response shapes and what must be configured before using each endpoint.

Here’s what this Spring Boot backend is doing, and what you need to configure before you can run or test the endpoints.

## Checklist
- [x] Identify the project’s purpose and entry points
- [x] Explain each key file
- [x] Explain the request/response models
- [x] List required configuration before calling endpoints
- [x] Point out likely runtime dependencies and pitfalls

## What this project is

This backend is a Spring Boot app named `SunwayIzoneScraper` that exposes REST endpoints for:

1. **Scraping a Sunway iZone timetable** using Selenium + Jsoup
2. **Generating AI study recommendations** using Spring AI with an Ollama model

The main endpoint controller is `src/main/java/com/izonescraper/sunwayizonescraper/TimeTableController.java`.

---

## File-by-file explanation

### `HELP.md`
This is the default Spring Boot help file. It’s mostly generic project boilerplate and doesn’t contain your app-specific setup steps yet.

Relevant parts:
- Mentions Spring Web / Spring Web Services guides
- Explains Maven parent inheritance behavior

**Important:** it does **not** document your real runtime requirements like Ollama, ChromeDriver, or the required request payloads.

---

### `pom.xml`
This defines project dependencies and build configuration.

#### Important dependencies
- `spring-boot-starter-webmvc`
    - Provides Spring MVC for REST endpoints
- `spring-boot-starter-webservices`
    - SOAP/web services support
- `lombok`
    - Used in DTO classes like `UserDTO`
- `jsoup`
    - Parses scraped HTML
- `selenium-java`
    - Drives the browser login/timetable scraping flow
- `spring-ai-starter-model-ollama`
    - Enables the AI endpoint via Ollama

#### Important build/runtime settings
- Java version: **17**
- Spring AI BOM version: **2.0.0**
- Spring Boot parent: **4.1.0**

#### Why this matters
Before running the app, you need the runtime dependencies that match this POM:
- Java 17
- A working browser driver setup for Selenium
- Ollama running locally if you use the AI endpoint

---

### `src/main/resources/application.yaml`
This is the most important configuration file for runtime behavior.

```yaml
spring:
  application:
    name: SunwayIzoneScraper
  ai:
    ollama:
      base-url: http://localhost:11434
      chat:
        model: llama3.2
        temperature: 0.3
server:
  port: 8020
  address: 0.0.0.0
```

#### What it configures
- **App name**: `SunwayIzoneScraper`
- **Ollama base URL**: `http://localhost:11434`
- **Model**: `llama3.2`
- **Temperature**: `0.3`
- **Server port**: `8020`
- **Bind address**: `0.0.0.0` so it listens on all interfaces

#### What must be configured before running
1. **Ollama must be installed and running**
    - The app expects Ollama at `http://localhost:11434`
2. **The model must exist**
    - `llama3.2` should be pulled in Ollama
3. **Port 8020 must be free**
4. **If accessing from another device**, `0.0.0.0` is correct, but your firewall must allow inbound traffic to port 8020

---

### `TimeTableController.java`
This is the REST controller exposing the API.

#### Base path
```java
@RequestMapping("/api/timetable")
```

#### Endpoints

##### `POST /api/timetable/scrape`
```java
public Object scrapeTimeTable(@RequestBody UserDTO user)
```
- Accepts a `UserDTO`
- Calls `timeTableService.getTimeTable(user)`
- Returns scraped timetable data or an error string

##### `POST /api/timetable/ai`
```java
public AIResponseFormat aiRecommendations(@RequestBody UserAIRequest userAIRequest)
```
- Accepts a `UserAIRequest`
- Calls `timeTableService.getAIRecommendations(userAIRequest)`
- Returns AI-generated study plan data

#### What to know before using these endpoints
- `/scrape` requires valid **Sunway iZone login credentials**
- `/ai` requires a timetable payload plus an intensity level
- Both endpoints depend on service-layer logic and the configured runtime environment

---

### `TimeTableService.java`
This contains the real logic.

---

## `getAIRecommendations(UserAIRequest userAIRequest)`

This method:
1. Computes study hours from intensity:
   ```java
   private double getStudyHours(int intensity){
       return 2 + (intensity * 1.6);
   }
   ```
2. Builds a prompt using the timetable data
3. Sends the prompt to the AI model through `ChatClient`
4. Parses the response into `AIResponseFormat`

### What this endpoint needs configured
- Ollama running
- Correct model name in `application.yaml`
- Valid `UserAIRequest` body

### Input model for AI
`UserAIRequest.java` contains:
- `List<TableHeader> tableHeader`
- `int intensityLevel`

So your request must include:
- timetable data
- intensity level

### Output model
`AIResponseFormat.java` is:
```java
public record AIResponseFormat(List<StudySlot> studySlots) {}
```
So the AI is expected to return JSON that matches that schema.

---

## `getTimeTable(UserDTO user)`

This method:
1. Starts Chrome in headless mode
2. Opens the Sunway login page
3. Logs in using student credentials
4. Navigates to the timetable page
5. Parses page HTML with Jsoup
6. Extracts rows and cells into `TableHeader` and `TableData`
7. Returns the list of table rows

### External services it depends on
- `https://izone.sunway.edu.my/login`
- `https://izone.sunway.edu.my/timetable`

### What must be configured before using `/scrape`
1. **Valid Sunway iZone credentials**
2. **Chrome installed**
3. **ChromeDriver available and compatible**
    - Selenium uses `new ChromeDriver(options)`
    - That usually means ChromeDriver must be on PATH or otherwise resolvable
4. **Network access to the Sunway portal**
5. **The portal’s DOM structure must match the selectors used**
    - If the site layout changes, scraping may break

### Parsing assumptions in the code
The scraper looks for:
- login form fields:
    - `name="student_uid"`
    - `name="password"`
- submit button:
    - `button[type='submit']`
- logout indicator:
    - `#logoutUrl`
- timetable table:
    - `table.table.table-bordered.table-bordered-print`
- rows:
    - `table[data-role='table'] tr`

If any of these change, scraping may fail.

---

## DTO / model files

### `Scrape/UserDTO.java`
Used by `/scrape`.

Fields:
- `studentId`
- `password`

Example JSON:
```json
{
  "studentId": "22001234",
  "password": "your-password"
}
```

---

### `AI/UserAIRequest.java`
Used by `/ai`.

Fields:
- `tableHeader`
- `intensityLevel`

Example JSON shape:
```json
{
  "tableHeader": [
    {
      "header": "Monday",
      "tableDataList": [
        {
          "tableDataDetails": ["Math", "8:00 AM", "10:00 AM"]
        }
      ]
    }
  ],
  "intensityLevel": 3
}
```

---

### `Scrape/TableHeader.java`
Represents one timetable row/group.

Fields:
- `Header` — note the capitalized field name in the code
- `tableDataList`

This class is used both in scraping output and AI input.

---

### `Scrape/TableData.java`
Represents a single timetable cell.

Fields:
- `tableDataDetails` — a list of strings collected from the cell

---

### `AI/AIResponseFormat.java`
Represents the AI response.

Fields:
- `studySlots` — a list of `StudySlot`

This means the AI endpoint expects structured JSON back, not free text.

---

## What to configure before running or testing endpoints

### 1. Java and Maven
Make sure the project is run with:
- **Java 17**

### 2. Ollama setup for `/ai`
You need:
- Ollama installed
- Ollama running on `localhost:11434`
- Model `llama3.2` available

If not, `/api/timetable/ai` will fail when the app tries to call the model.

### 3. Selenium + ChromeDriver for `/scrape`
You need:
- Google Chrome installed
- ChromeDriver compatible with your Chrome version
- Selenium able to launch Chrome headlessly

Without this, `/api/timetable/scrape` will fail before login completes.

### 4. Sunway portal access
You need:
- Working Sunway iZone credentials
- Access to the login/timetable pages
- The portal selectors still matching the code

### 5. Server port
The app runs on:
- `http://localhost:8020`

So your endpoints become:
- `POST http://localhost:8020/api/timetable/scrape`
- `POST http://localhost:8020/api/timetable/ai`

### 6. Firewall/network
Because the server binds to `0.0.0.0`, it can accept external connections, but Windows Firewall may still block it.

---

## Quick endpoint summary

### `POST /api/timetable/scrape`
Purpose:
- Log in to iZone and scrape timetable

Body:
- `UserDTO`

Needs:
- Student ID
- Password
- Selenium/ChromeDriver
- Access to Sunway portal

---

### `POST /api/timetable/ai`
Purpose:
- Generate study recommendations from timetable data

Body:
- `UserAIRequest`

Needs:
- Scraped timetable data
- `intensityLevel`
- Ollama running locally
- `llama3.2` model available

---

## Practical startup checklist
Before assessing any endpoint, verify:

- [ ] Java 17 is installed
- [ ] App starts on port 8020
- [ ] Ollama is running at `http://localhost:11434`
- [ ] `llama3.2` is available in Ollama
- [ ] Chrome + ChromeDriver are configured
- [ ] Sunway iZone login credentials are valid
- [ ] The portal pages still match the CSS/DOM selectors used in `TimeTableService`
- [ ] You’re sending the correct JSON body for the endpoint

---

## One important note
`HELP.md` itself does **not** include the real setup instructions for this app. The actual configuration is mostly defined in:
- `pom.xml`
- `src/main/resources/application.yaml`
- `TimeTableController.java`
- `TimeTableService.java`
