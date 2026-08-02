package com.izonescraper.sunwayizonescraper.AI;


import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record AIResponseFormat (@JsonProperty("studySlots") List<StudySlot> studySlots){

}
