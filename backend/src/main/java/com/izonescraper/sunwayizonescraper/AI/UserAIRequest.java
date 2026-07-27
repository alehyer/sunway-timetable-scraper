package com.izonescraper.sunwayizonescraper.AI;

import com.izonescraper.sunwayizonescraper.Scrape.TableHeader;
import lombok.Data;

import java.util.List;

@Data
public class UserAIRequest {
    List<TableHeader> tableHeader;
    int intensityLevel;
}
