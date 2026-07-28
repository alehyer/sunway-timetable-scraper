package com.izonescraper.sunwayizonescraper;

import com.izonescraper.sunwayizonescraper.AI.AIResponseFormat;
import com.izonescraper.sunwayizonescraper.AI.UserAIRequest;
import com.izonescraper.sunwayizonescraper.Scrape.UserDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/timetable")
public class TimeTableController {

    @Autowired
    TimeTableService timeTableService;

    @PostMapping("/scrape")
    public Object scrapeTimeTable(@RequestBody UserDTO user){
        return timeTableService.getTimeTable(user);
    };

    @PostMapping("/ai")
    public AIResponseFormat aiRecommendations(@RequestBody UserAIRequest userAIRequest){
        return timeTableService.getAIRecommendations(userAIRequest);
    }



}
