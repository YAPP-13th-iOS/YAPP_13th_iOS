//
//  FruitResponse.swift
//  FruitSchool
//
//  Created by Presto on 2018. 9. 17..
//  Copyright © 2018년 YAPP. All rights reserved.
//

/*
 과일 세부정보 응답 모델
 */
struct FruitResponse: Codable {
    struct Data: Codable {
        let id: String
        let title: String
        let english: String
        let grade: Int
        let season: String
        let standardTip: StandardTip
        let nutritionTip: NutritionTip
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case title, english, grade, season, standardTip, nutritionTip
        }
    }
    let message: String
    let data: [Data]
}

struct StandardTip: Codable {
    let purchasingTip: String
    let storageTemperature: String?
    let storageDate: String?
    let storageMethod: String?
    let careMethod: String?
    var tips: [(title: String, content: String)] {
        let array = [("구입 요령", purchasingTip), ("보관 온도", storageTemperature), ("보관일", storageDate), ("보관법", storageMethod), ("손질법", careMethod)]
        let filtered = array.filter { $0.1 != nil }
        return filtered as? [(title: String, content: String)] ?? [(title: String, content: String)]()
    }
    var validCount: Int {
        var count = 1
        if storageTemperature != nil {
            count += 1
        }
        if storageDate != nil {
            count += 1
        }
        if storageMethod != nil {
            count += 1
        }
        if careMethod != nil {
            count += 1
        }
        return count
    }
}

struct NutritionTip: Codable {
    let sodium: Double
    let protein: Double
    let sugar: Double
    var sodiumText: String {
        return "\(sodium)mg"
    }
    var proteinText: String {
        return "\(protein)g"
    }
    var sugarText: String {
        return "\(sugar)g"
    }
}
