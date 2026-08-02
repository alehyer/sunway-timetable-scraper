package com.izonescraper.sunwayizonescraper;

import com.izonescraper.sunwayizonescraper.AI.AIResponseFormat;
import com.izonescraper.sunwayizonescraper.AI.UserAIRequest;
import com.izonescraper.sunwayizonescraper.Scrape.TableData;
import com.izonescraper.sunwayizonescraper.Scrape.TableHeader;
import com.izonescraper.sunwayizonescraper.Scrape.UserDTO;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.openqa.selenium.By;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.converter.BeanOutputConverter;
import org.springframework.stereotype.Service;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@Service
public class TimeTableService {

    private ChatClient chatClient;

    public TimeTableService(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }


    private int getStudyHours(int intensity){
        return 2 + (intensity * 2);
    }

    public AIResponseFormat getAIRecommendations(UserAIRequest userAIRequest){

        int studyHours = getStudyHours(userAIRequest.getIntensityLevel());

        // 1. Create a BeanOutputConverter for your target DTO
        var outputConverter = new BeanOutputConverter<>(AIResponseFormat.class);
        String userPrompt = """
        Student's Current Timetable:
        %s

        Total Required Extra Study Time: %d hours

        Task:
        1. Identify free gaps in the current timetable.
        2. Create a complementary study schedule that fills those gaps up, and the created gaps time combined must match the total %d hours requested.
        3. Match study sessions to subjects from the current timetable.

        %s
        """.formatted(
                userAIRequest.getTableHeader(),
                studyHours,
                studyHours,
                outputConverter.getFormat() // Appends machine-generated JSON schema instructions
        );
        return chatClient.prompt()
                .system("You are an academic scheduling assistant for Sunway University students.")
                .user(userPrompt)
                .call()
                .entity(AIResponseFormat.class);
    }



    Object getTimeTable(UserDTO user) {
        // Optional: Run in headless mode so no physical browser window pops up
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--headless=new");

        // 2. Set explicit dimensions (headless defaults to a tiny window, causing responsive elements to hide)
        options.addArguments("--window-size=1920,1080");

        // 3. Override the default Headless User-Agent string to look like a standard browser
        options.addArguments("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

        // 4. Bypass sandbox/GPU issues commonly hit in server/container environments
        options.addArguments("--no-sandbox");
        options.addArguments("--disable-dev-shm-usage");
        options.addArguments("--disable-blink-features=AutomationControlled");

        WebDriver driver = new ChromeDriver(options);
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

        try {
            driver.get("https://izone.sunway.edu.my/login");

            WebElement usernameField = wait.until(ExpectedConditions.presenceOfElementLocated(By.name("student_uid")));
            WebElement passwordField = driver.findElement(By.name("password"));
            WebElement loginButton = driver.findElement(By.cssSelector("button[type='submit']"));

            usernameField.sendKeys(user.getStudentId());
            passwordField.sendKeys(user.getPassword());
            loginButton.click();

            try {
                wait.until(ExpectedConditions.textToBePresentInElementLocated(
                        By.tagName("body"), "Invalid Student ID or Password"
                ));
                return "Invalid username or password";
            } catch (TimeoutException e) {
                // Error text not found, move to success check
            }

            wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("logoutUrl")));
            System.out.println("Successfully logged in! Current URL: " + driver.getCurrentUrl());

            // 1. Navigate to timetable
            driver.get("https://izone.sunway.edu.my/timetable");

            // 2. Enhanced Wait: Wait until rows AND headers are visible/populated
            wait.until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector("table.table.table-bordered.table-bordered-print")));

            



            // 3. Parse Source
            String pageSource = driver.getPageSource();
            Document doc = Jsoup.parse(pageSource);

            // 4. Extract data using the exact class match
            Elements timeTableRows = doc.select("table[data-role='table'] tr");
            List<TableHeader> tableHeaderList = new ArrayList<>();

            for (Element row : timeTableRows) {
                TableHeader tableHeader = new TableHeader();
                String headerText = row.select("th").text();

                // Skip empty spacer rows if the portal uses them
                if (headerText.isEmpty() && row.select("td").isEmpty()) {
                    continue;
                }

                tableHeader.setHeader(headerText);

                List<TableData> tdList = new ArrayList<>();
                Elements tdElements = row.select("td");

                for (Element tdElement : tdElements) {

                    TableData tableData = new TableData();

                    Element strongElement = tdElement.selectFirst(":root > strong");
                    List<String> arrayForTableDataDetails = new ArrayList<>();

                    if (strongElement != null) {
                        arrayForTableDataDetails.add(strongElement.text());
                    } else {
                        arrayForTableDataDetails.add("No subject"); // or handle as needed
                    }


                    Elements spanElements = tdElement.select("span");
                    for (Element span : spanElements) {
                        arrayForTableDataDetails.add(span.text());
                    }

                    tableData.setTableDataDetails(arrayForTableDataDetails);
                    tdList.add(tableData);
                }

                tableHeader.setTableDataList(tdList);
                tableHeaderList.add(tableHeader);
            }

            System.out.println("Scraped Rows: " + tableHeaderList.size());
            System.out.println(tableHeaderList);

            return tableHeaderList;

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            driver.quit();
        }


        return "Failed to scrape data";
    }




    }



