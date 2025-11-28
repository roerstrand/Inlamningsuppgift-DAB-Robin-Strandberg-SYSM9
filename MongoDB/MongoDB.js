use smallDogs;

    db.smallDogs.insertMany([

        {
            name: "Chihuahua",
            origin: "Mexico",
            height: { min: 8, max: 23, unit: "cm"},
            weight: { min: 1, max: 3, unit: "kg"},
            lifeExpectancy: { min: 12, max: 20, unit: "years"},
            commonColors: [ "Fawn", "Cream", "Red", "Black"]
            },

        {
            name: "Pomeranian",
            origin: ["Germany", "Poland", "Pomerania"],
            height: { min: 18, max: 22, unit: "cm" },
            weight: { min: 1.4, max: 3.2, unit: "kg"},
            lifeExpectancy: { min: 12, max: 16, unit: "years"},
            commonColors: [ "Orange", "Black", "Cream", "White"]
            },

        {
            name: "Bichón Havanés",
            origin: "Cuba",
            height: { min: 22, max: 29, unit: "cm"},
            weight: { min: 3, max: 6, unit: "kg"},
            lifeExpectancy: { min: 14, max: 16, unit: "years"},
            commonColors: [ "Black", "Cream", "Gold", "Red"]
            },

        {
            name: "Pug",
            origin: "China",
            height: { min: 25, max: 36, unit: "cm"},
            weight: { min: 6.35, max: 8.16, unit: "kg"},
            lifeExpectancy: { min: 12, max: 15, unit: "years"},
            commonColors: [ "Fawn", "Black", "Silver", "Apricot"]
            },

        ]);

    db.smallDogs.insertOne(
        {
            name: "Shih Tzu",
            origin: "Tibet",
            height: { min: 20, max: 28, unit: "cm"},
            weight: { min: 4, max: 7.5, unit: "kg"},
            lifeExpectancy: { min: 10, max: 16, unit: "years"},
            commonColors: [ "Black", "White", "Gold", "Silver"]});

    db.smallDogs.find()

    db.smallDogs.updateOne({ "Shih Tzu"}, { $set: { litterSize: { min: 2, max: 9 } } })

    db.smallDogs.deleteOne( { name: "Chihuahua"} )

    db.smallDogs.find ( { name: "Pomeranian"})

    db.smallDogs.find(
        {
            "lifeExpectancy.min": {$gte: 12},
            "lifeExpectancy.max": {$lte: 18 }
            }).sort( { "lifeExpectancy.min": 1, name: 1, _id: 0} )

    db.smallDogs.updateOne(
        { name: "Bichón Havanés" },
        { $push: { commonColors: "Chocolate" } }
        )

    db.smallDogs.updateOne( { name: "Pomeranian"}, { $pull: { commonColors: "White"},
        $push: { commonColors: "Sable"}})

    db.smallDogs.countDocuments()

    db.smallDogs.countDocuments(
        { "height.max": { $gte: 25} } )

    db.smallDogs.createIndex( { name: 1}, {unique: true })

    // Kan ej lägga in pga unikt index

    db.smallDogs.insertOne( { name: "Pomeranian"})

    db.smallDogs.updateMany( {}, { $set: { favorite: false }})

    db.smallDogs.updateMany( { name: { $in: ["Pomeranian", "Shih Tzu" ]}}, { $set: { favorite: true }} )

    db.smallDogs.updateMany( { favorite: true}, { $set: { shouldPurchase: true }})

    db.smallDogs.countDocuments( { favorite: true })

    db.smallDogs.find( { favorite: true}, { name: 1, _id: 0, origin: 1, lifeExpectancy: 1 }).sort( { "lifeExpectancy.min":1 })