package com.izonescraper.sunwayizonescraper.AI;

import com.fasterxml.jackson.annotation.JsonProperty;

public record StudySlot(@JsonProperty("date") String date,
                        @JsonProperty("subject") String subject,
                        @JsonProperty("time") String time) {
}
