local _, ns = ...

-- GÉNÉRÉ AUTOMATIQUEMENT par tools/gen_routes.py à partir de QuestieDB (Forever).
-- Ne pas modifier à la main : régénérer. Parcours : alliance-nightelf

ns.RegisterGuide({
    id = "alliance-nightelf-01-teldrassil",
    name = "Teldrassil 1-14",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 1, maxLevel = 14,
    next = "alliance-nightelf-14-darkshore",
    text = [[
M teldrassil
G "Rejoins Teldrassil" @58.7,44.3 r=40 upto=16
A 456 @58.7,44.3 id=2079
A 458 @59.9,42.5 id=2077
C 456 @61.5,43.6 mobs=2031,1984
A 4495 @60.9,42.0 id=8583
T 456 @58.7,44.3 id=2079
A 457 @58.7,44.3 id=2079
T 458 @57.8,45.2 id=1992
A 459 @57.8,45.2 id=1992
C 459 @55.3,44.8 mobs=1989,1988
T 459 @57.8,45.2 id=1992
A 916 @57.8,41.6 id=2082
C 457 @61.3,36.2 mobs=2032,1985
T 457 @58.7,44.3 id=2079
A 2159 @61.2,47.6 id=6780
A 488 @60.5,56.3 id=2150
T 2159 @55.6,59.8 id=6736
A 475 @56.0,57.3 id=2078
A 932 @55.6,57.0 id=3567
A 997 @56.1,57.7 id=2083
A 2438 @55.6,57.0 id=3567
C 488 @52.2,60.0 mobs=2042,1998,1995,1996,2043
A 487 @54.6,58.5 id=2151
T 488 @60.5,56.3 id=2150
A 489 @56.1,57.7 id=2083
C 489 @51.6,58.8
C 932 @51.8,50.4 mobs=2038
T 932 @55.6,57.0 id=3567
T 489 @60.5,56.3 id=2150
T 475 @66.3,58.5 id=2107
A 476 @66.3,58.5 id=2107
C 2438 @68.0,59.6
T 997 @60.9,68.5 id=2080
A 918 @60.9,68.5 id=2080
A 919 @60.9,68.5 id=2080
C 918 @60.9,67.2 mobs=2022,2025,2027,2029,2030
T 918 @60.9,68.5 id=2080
T 2438 @55.6,57.0 id=3567
T 476 @56.0,57.3 id=2078
A 483 @56.0,57.3 id=2078
C 919 @52.7,71.0
T 919 @60.9,68.5 id=2080
A 2541 @44.9,61.6 id=7317
C 483 @44.3,61.4
C 2541 @44.5,59.3 mobs=2009
T 2541 @44.9,61.6 id=7317
C 487 @46.5,53.3 mobs=2152
T 487 @54.6,58.5 id=2151
T 483 @56.0,57.3 id=2078
A 486 @56.0,57.3 id=2078
T 4495 @54.6,33.0 id=8584
A 3519 @54.6,33.0 id=8584
C 916 @56.6,27.8 mobs=1986
T 916 @57.8,41.6 id=2082
A 917 @57.8,41.6 id=2082
T 3519 @60.9,42.0 id=8583
A 3521 @60.9,42.0 id=8583
C 3521 @56.6,27.8 mobs=1986,1989
C 917 @56.8,26.5
T 917 @57.8,41.6 id=2082
A 920 @57.8,41.6 id=2082
T 920 @59.1,39.5 id=3514
T 3521 @60.9,42.0 id=8583
A 3522 @60.9,42.0 id=8583
T 3522 @54.6,33.0 id=8584
A 937 @38.3,34.4 id=3519
C 937 @35.3,36.6 mobs=2017,2021,2015,2020,2018
T 937 @38.3,34.4 id=3519
A 931 @34.6,28.8
T 931 @60.9,68.5 id=2080
A 2399 @60.8,68.6
T 2399 @60.8,68.6
A 930 @42.6,76.2
C 486 @38.8,79.8 mobs=2039
T 486 @56.0,57.3 id=2078
T 930 @60.9,68.5 id=2080
L 14 "Tue des monstres autour de toi jusqu'au niveau 14"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-14-darkshore",
    name = "Sombrivage 14-21",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 14, maxLevel = 21,
    next = "alliance-nightelf-21-ashenvale",
    text = [[
M darkshore
G "Rejoins Sombrivage" @37.3,43.6 r=40 upto=23
A 947 @37.3,43.6 id=3583
A 983 @37.0,44.1 id=3666
A 3524 @36.6,45.6 id=10219
A 963 @35.7,43.7 id=3644
C 983 @35.7,48.4 mobs=2231,2234,2232,2236,2235
T 983 @36.6,46.3
A 1001 @36.6,46.3
C 3524 @36.4,50.9
T 3524 @36.6,45.6 id=10219
A 4681 @36.6,45.6 id=10219
A 982 @38.1,41.2 id=6301
A 958 @37.4,40.1 id=3649
C 1001 @33.8,35.8 mobs=2185,2187
C 982 @38.9,28.1
T 1001 @42.0,28.6
A 1002 @42.0,28.6
T 982 @38.1,41.2 id=6301
C 4681 @31.8,46.3
T 4681 @36.6,45.6 id=10219
A 953 @40.3,59.7 id=3639
C 963 @41.8,60.7 mobs=3667
C 958 @42.7,60.2 mobs=2177,2178,2176
C 953 @43.3,58.7
T 953 @40.3,59.7 id=3639
A 4722 @37.1,62.2
C 1002 @40.1,68.1 mobs=2070,2069,2237,2071
A 4728 @36.0,70.9
A 4730 @32.7,80.8
T 4722 @36.6,45.6 id=10219
T 4728 @36.6,45.6 id=10219
T 4730 @36.6,45.6 id=10219
A 1138 @36.1,44.9 id=10216
T 963 @35.7,43.7 id=3644
T 958 @37.4,40.1 id=3649
A 965 @39.0,43.5 id=3657
A 4723 @41.9,31.5
A 4725 @44.2,20.6
T 1002 @51.3,24.6
A 1003 @51.3,24.6
C 1138 @51.7,21.6 mobs=2235,2233
A 4727 @53.1,18.1
T 965 @55.0,24.9 id=3661
A 966 @55.0,24.9 id=3661
C 966 @56.3,26.7 mobs=2336
T 966 @55.0,24.9 id=3661
A 967 @55.0,24.9 id=3661
C 947 @55.7,35.1
T 947 @37.3,43.6 id=3583
A 948 @37.3,43.6 id=3583
T 1138 @36.1,44.9 id=10216
T 4723 @36.6,45.6 id=10219
T 4725 @36.6,45.6 id=10219
T 4727 @36.6,45.6 id=10219
T 948 @43.5,76.3 id=3616
C 1003 @39.4,81.4 mobs=2165,6788
T 1003 @41.4,80.6
A 4731 @31.7,83.7
A 4732 @31.2,85.6
A 4733 @31.3,87.4
T 4731 @36.6,45.6 id=10219
T 4732 @36.6,45.6 id=10219
T 4733 @36.6,45.6 id=10219
L 17 "Tue des monstres autour de toi jusqu'au niveau 17"
A 729 @37.4,41.8 id=2913
T 729 @35.7,83.7 id=2917
A 2098 @56.7,13.5 id=6667
C 2098 @39.3,28.4 mobs=2323,2202,2236,2203,2208
T 2098 @56.7,13.5 id=6667
L 21 "Tue des monstres autour de toi jusqu'au niveau 21"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-21-ashenvale",
    name = "Orneval 21-22",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 21, maxLevel = 22,
    next = "alliance-nightelf-22-westfall",
    text = [[
M ashenvale
G "Rejoins Orneval" @36.6,49.6 r=40 upto=24
A 991 @36.6,49.6 id=3691
A 1008 @34.7,48.8 id=3845
T 967 @26.2,38.7 id=3663
A 970 @26.2,38.7 id=3663
A 1010 @26.4,38.6 id=3847
T 991 @20.3,42.3 id=3891
A 1023 @20.3,42.3 id=3891
C 1023 @20.4,42.7 mobs=3737,3739,3742,3740
A 1007 @14.8,31.3 id=3846
C 1007 @14.2,20.6
T 1007 @14.8,31.3 id=3846
C 1008 @7.1,14.0 mobs=3717,3944,3711,3712,3715
C 1010 @32.0,22.6
C 970 @31.4,30.7 mobs=3725,3730,3728,3727
T 970 @26.2,38.7 id=3663
T 1010 @26.4,38.6 id=3847
A 973 @26.2,38.7 id=3663
A 1020 @26.4,38.6 id=3847
T 1008 @34.7,48.8 id=3845
T 1023 @36.6,49.6 id=3691
A 1024 @36.6,49.6 id=3691
A 1025 @36.6,49.6 id=3691
T 1020 @37.4,51.8 id=3894
A 1033 @37.4,51.8 id=3894
C 1033 @46.4,46.4
T 1024 @53.5,46.2 id=3916
C 1025 @54.4,62.9 mobs=3743,3750,3746,3749
T 1033 @37.4,51.8 id=3894
A 1034 @37.4,51.8 id=3894
T 1025 @36.6,49.6 id=3691
A 1054 @36.6,49.6 id=3691
C 1054 @37.7,34.7 mobs=3987
T 1054 @36.6,49.6 id=3691
C 1034 @33.3,67.8
C 973 @25.3,60.7 mobs=3664
T 1034 @37.4,51.8 id=3894
T 973 @26.2,38.7 id=3663
A 1009 @14.8,31.3 id=3846
C 1009 @7.2,13.1 mobs=10559,3943
T 1009 @14.8,31.3 id=3846
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-22-westfall",
    name = "Marche de l'Ouest 22-25",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 22, maxLevel = 25,
    next = "alliance-nightelf-25-redridge",
    text = [[
M westfall
G "Rejoins Marche de l'Ouest" @30.0,86.0 r=40 upto=27
A 103 @30.0,86.0 id=392
A 104 @30.0,86.0 id=392
A 152 @30.0,86.0 id=392
C 104 @29.3,76.0 mobs=391
C 152 @27.1,72.4 mobs=171,517,126,127
T 104 @30.0,86.0 id=392
T 152 @30.0,86.0 id=392
A 65 @56.3,47.5 id=234
C 103 @52.3,23.8 mobs=573,1032,114,36,1030
T 103 @30.0,86.0 id=392
L 25 "Tue des monstres autour de toi jusqu'au niveau 25"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-25-redridge",
    name = "Les Carmines 25-26",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 25, maxLevel = 26,
    next = "alliance-nightelf-26-duskwood",
    text = [[
M redridge
G "Rejoins Les Carmines" @22.6,47.4 r=40 upto=28
T 65 @21.4,45.4 id=266
A 127 @22.6,47.4 id=381
A 150 @22.6,47.4 id=381
A 180 @21.7,46.4
A 91 @24.6,44.3 id=900
A 20 @28.4,49.0 id=382
A 128 @26.4,57.9 id=903
A 34 @16.8,46.3 id=342
C 34 @10.6,49.3 mobs=345
T 34 @16.8,46.3 id=342
C 20 @25.6,10.9 mobs=485,440,4463,437,435
C 128 @24.6,11.7 mobs=435
T 20 @28.4,49.0 id=382
T 128 @26.4,57.9 id=903
C 127 @52.6,57.5 mobs=422,548,545,578,14270
C 150 @52.6,57.5 mobs=46,1418,732,422,548
C 91 @73.5,48.0 mobs=568,429,431,433,432
C 180 @75.1,37.1 mobs=703
T 180 @24.9,44.5 id=344
T 91 @24.6,44.3 id=900
T 127 @22.6,47.4 id=381
T 150 @22.6,47.4 id=381
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-26-duskwood",
    name = "Bois de la Pénombre 26-28",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 26, maxLevel = 28,
    next = "alliance-nightelf-28-wetlands",
    text = [[
M duskwood
G "Rejoins Bois de la Pénombre" @75.8,45.3 r=40 upto=30
A 66 @75.8,45.3 id=265
A 101 @75.8,45.3 id=265
A 173 @75.8,47.6 id=663
A 163 @75.3,48.8 id=633
A 164 @75.3,48.8 id=633
A 165 @75.3,48.8 id=633
T 66 @72.5,46.9 id=267
A 56 @73.5,46.8 id=264
A 90 @73.8,43.5 id=272
A 174 @79.8,48.0 id=276
C 56 @79.4,70.8 mobs=48,203
T 56 @73.5,46.8 id=264
A 57 @73.5,46.8 id=264
C 173 @64.2,69.9 mobs=533
T 173 @75.8,47.6 id=663
A 221 @75.8,47.6 id=663
C 221 @64.5,72.8 mobs=205
T 221 @75.8,47.6 id=663
A 245 @45.1,67.0 id=888
T 163 @18.4,56.4 id=288
A 5 @18.4,56.4 id=288
C 57 @21.1,45.4 mobs=202,531
C 101 @24.0,33.4 mobs=930,539,217,569,202
T 165 @28.1,31.5 id=289
A 148 @28.1,31.5 id=289
C 90 @35.0,24.8 mobs=3823,923,213,3824,565
T 164 @7.8,34.1 id=311
A 95 @7.8,34.1 id=311
A 226 @7.7,33.2 id=893
C 226 @19.5,26.7 mobs=213,565
T 226 @7.7,33.2 id=893
C 245 @10.4,55.5 mobs=539
T 245 @45.1,67.0 id=888
T 95 @49.9,77.7
A 230 @49.9,77.7
T 57 @73.5,46.8 id=264
A 58 @73.5,46.8 id=264
T 90 @73.8,43.5 id=272
T 5 @73.8,43.5 id=272
T 101 @75.8,45.3 id=265
T 148 @75.8,45.3 id=265
A 149 @75.8,45.3 id=265
T 149 @82.0,59.1 id=302
A 154 @82.0,59.1 id=302
T 154 @75.8,45.3 id=265
A 157 @75.8,45.3 id=265
T 157 @28.1,31.5 id=289
A 158 @28.1,31.5 id=289
C 58 @24.4,33.3 mobs=604
T 230 @7.8,34.1 id=311
A 262 @7.8,34.1 id=311
T 58 @73.5,46.8 id=264
T 158 @73.8,44.5 id=273
A 156 @73.8,44.5 id=273
T 262 @75.8,45.3 id=265
A 265 @75.8,45.3 id=265
T 265 @72.5,46.9 id=267
A 266 @72.5,46.9 id=267
T 266 @73.8,44.5 id=273
A 453 @73.8,44.5 id=273
T 453 @18.4,56.4 id=288
A 268 @18.4,56.4 id=288
C 156 @21.1,45.4 mobs=202,531
T 268 @7.8,34.1 id=311
A 323 @7.8,34.1 id=311
C 323 @16.1,35.6 mobs=785,1110,787
T 323 @7.8,34.1 id=311
T 156 @73.8,44.5 id=273
A 159 @73.8,44.5 id=273
T 159 @28.1,31.5 id=289
A 133 @28.1,31.5 id=289
C 133 @23.9,33.3 mobs=604,570,210,3,948
T 133 @28.1,31.5 id=289
A 134 @28.1,31.5 id=289
C 134 @33.4,76.3
T 134 @28.1,31.5 id=289
A 160 @28.1,31.5 id=289
T 160 @71.9,46.4 id=263
A 251 @71.9,46.4 id=263
T 251 @72.6,47.6 id=268
A 401 @72.6,47.6 id=268
T 401 @72.6,47.6 id=268
A 252 @72.6,47.6 id=268
T 252 @71.9,46.4 id=263
A 222 @75.8,47.6 id=663
C 222 @72.8,73.0 mobs=206,920
T 222 @75.8,47.6 id=663
A 223 @75.8,47.6 id=663
T 223 @75.3,49.0 id=661
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-28-wetlands",
    name = "Les Paluns 28-30",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 28, maxLevel = 30,
    next = "alliance-nightelf-30-ashenvale-2",
    text = [[
M wetlands
G "Rejoins Les Paluns" @10.8,55.9 r=40 upto=32
A 472 @10.8,55.9 id=2097
A 473 @10.1,56.9 id=2086
T 473 @9.9,57.5 id=2104
A 464 @9.9,57.5 id=2104
A 279 @8.3,58.6 id=1242
A 470 @11.8,58.0 id=2111
A 305 @11.5,52.2 id=2096
C 279 @13.9,40.2 mobs=1024,1259
T 279 @8.3,58.6 id=1242
A 281 @8.3,58.6 id=1242
T 281 @13.5,41.4
A 284 @13.5,41.4
T 284 @13.6,38.2
A 285 @13.6,38.2
T 285 @13.9,34.8
A 286 @13.9,34.8
T 286 @8.3,58.6 id=1242
T 305 @38.9,52.3 id=1076
A 299 @38.8,52.4 id=1077
A 306 @38.9,52.3 id=1076
A 294 @38.2,50.9 id=1078
C 299 @34.3,48.0
T 299 @38.8,52.4 id=1077
C 464 @47.1,45.8 mobs=1034,1057,1035,1036,1038
C 470 @44.5,25.5 mobs=1032,1033,1031
T 472 @49.8,18.3 id=1071
A 631 @49.9,18.2 id=1075
T 631 @51.3,8.0
A 632 @51.3,8.0
T 632 @49.9,18.2 id=1075
C 294 @24.3,50.0 mobs=1020,1021
T 306 @11.5,52.2 id=2096
T 470 @11.8,58.0 id=2111
T 464 @9.9,57.5 id=2104
A 465 @9.9,57.5 id=2104
T 294 @38.2,50.9 id=1078
A 295 @38.2,50.9 id=1078
C 295 @33.9,48.3 mobs=1022,1023
T 295 @38.2,50.9 id=1078
A 296 @38.2,50.9 id=1078
C 296 @33.3,51.5 mobs=1353
T 296 @38.2,50.9 id=1078
T 465 @47.5,47.0
L 30 "Tue des monstres autour de toi jusqu'au niveau 30"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-30-ashenvale-2",
    name = "Orneval 30-31",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 30, maxLevel = 31,
    next = "alliance-nightelf-31-duskwood-2",
    text = [[
M ashenvale
G "Rejoins Orneval" @21.7,53.3 r=40 upto=33
A 1021 @21.7,53.3 id=3901
A 1022 @22.2,53.0 id=3880
A 1140 @26.2,38.7 id=3663
A 4581 @34.7,48.8 id=3845
A 1035 @37.4,51.8 id=3894
C 1022 @50.5,39.1
A 1026 @53.5,46.2 id=3916
C 1026 @54.4,35.4
T 1026 @53.5,46.2 id=3916
C 1140 @66.6,57.0
T 1021 @78.3,44.8 id=3920
A 1031 @78.3,44.8 id=3920
C 1031 @78.0,42.4 mobs=10647,4619
T 4581 @85.2,44.7 id=3848
A 1011 @85.2,44.7 id=3848
C 174 @84.9,61.7 mobs=3374,3377,11684,3375,3993
C 1011 @75.3,72.0
C 1035 @66.7,82.2 mobs=3931
T 1011 @85.2,44.7 id=3848
A 1012 @85.2,44.7 id=3848
C 1012 @77.6,73.4 mobs=3940,3941,3942
T 1012 @85.2,44.7 id=3848
T 1035 @37.4,51.8 id=3894
T 1140 @26.2,38.7 id=3663
T 1022 @22.2,53.0 id=3880
T 1031 @21.7,53.3 id=3901
A 1032 @21.7,53.3 id=3901
C 1032 @81.1,49.8 mobs=3770,3755,3763,3771,3762
T 1032 @21.7,53.3 id=3901
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-31-duskwood-2",
    name = "Bois de la Pénombre 31-33",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 31, maxLevel = 33,
    next = "alliance-nightelf-33-hillsbrad",
    text = [[
M duskwood
G "Rejoins Bois de la Pénombre" @79.8,48.0 r=40 upto=35
T 174 @79.8,48.0 id=276
A 175 @79.8,48.0 id=276
T 175 @82.0,59.1 id=302
A 177 @82.0,59.1 id=302
C 177 @80.9,72.0 mobs=511
T 177 @79.8,48.0 id=276
A 181 @79.8,48.0 id=276
C 181 @37.0,81.5 mobs=300
T 181 @79.8,48.0 id=276
L 32 "Tue des monstres autour de toi jusqu'au niveau 32"
A 254 @28.9,30.8
T 254 @28.9,30.8
A 225 @17.7,29.1
T 225 @72.6,47.6 id=268
A 227 @72.6,47.6 id=268
T 227 @73.5,46.8 id=264
L 33 "Tue des monstres autour de toi jusqu'au niveau 33"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-33-hillsbrad",
    name = "Contreforts de Hautebrande 33-34",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 33, maxLevel = 34,
    next = "alliance-nightelf-33-stv",
    text = [[
M hillsbrad
G "Rejoins Contreforts de Hautebrande" @51.5,58.4 r=40 upto=35
A 536 @51.5,58.4 id=2228
A 555 @51.9,58.7 id=2430
A 659 @50.4,59.0 id=2711
C 536 @43.9,68.0 mobs=2377,2376
T 536 @51.5,58.4 id=2228
A 559 @51.5,58.4 id=2228
C 555 @68.1,28.9 mobs=5431,2408,2505,4397,6352
T 555 @51.9,58.7 id=2430
C 559 @26.6,72.4 mobs=2375,2374,2376,2377,14276
T 559 @51.5,58.4 id=2228
A 560 @51.5,58.4 id=2228
T 560 @49.5,58.7 id=2263
A 561 @49.5,58.7 id=2263
T 561 @51.5,58.4 id=2228
A 562 @51.5,58.4 id=2228
C 562 @57.7,69.4 mobs=2371,2369
T 562 @51.5,58.4 id=2228
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-33-stv",
    name = "Vallée de Strangleronce 33-37",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 33, maxLevel = 37,
    next = "alliance-nightelf-37-arathi",
    text = [[
M stv
G "Rejoins Vallée de Strangleronce" @27.0,77.1 r=40 upto=39
A 189 @27.0,77.1 id=737
A 198 @26.9,77.2 id=773
A 213 @27.0,77.1 id=737
A 605 @27.1,77.2 id=2498
A 575 @28.3,77.6 id=2495
C 605 @43.1,47.8 mobs=1551,690,689,1550,688
C 213 @44.0,19.0 mobs=1096
C 575 @40.2,12.9 mobs=1150
A 583 @35.7,10.5 id=716
T 583 @35.7,10.8 id=715
A 185 @35.6,10.6 id=717
A 190 @35.5,10.6 id=718
A 194 @35.7,10.8 id=715
C 185 @34.2,11.7 mobs=681
T 185 @35.6,10.6 id=717
A 186 @35.6,10.6 id=717
T 198 @38.0,3.4 id=738
A 203 @38.0,3.3 id=733
A 204 @38.0,3.3 id=733
A 215 @38.0,3.4 id=738
T 215 @38.0,3.0 id=469
A 200 @38.0,3.0 id=469
T 200 @43.7,9.4
C 203 @44.8,10.2 mobs=937
C 204 @44.7,10.3 mobs=940,937,942,941
A 328 @43.7,9.4
C 190 @41.9,12.2 mobs=683
C 186 @46.7,15.1 mobs=682
T 328 @49.6,7.6
A 329 @49.6,7.6
T 203 @38.0,3.3 id=733
T 204 @38.0,3.3 id=733
T 329 @38.0,3.0 id=469
A 210 @37.7,3.3 id=770
A 330 @38.0,3.0 id=469
T 330 @37.7,3.4 id=1422
A 331 @37.7,3.4 id=1422
T 331 @38.0,3.0 id=469
T 190 @35.5,10.6 id=718
T 186 @35.6,10.6 id=717
A 187 @35.6,10.6 id=717
A 191 @35.5,10.6 id=718
C 187 @32.5,18.3 mobs=1085
C 191 @28.8,14.6 mobs=736
C 194 @25.6,16.2 mobs=685
C 189 @24.8,10.9 mobs=701,588,671,597,595
T 194 @35.7,10.8 id=715
T 187 @35.6,10.6 id=717
T 191 @35.5,10.6 id=718
A 188 @35.6,10.6 id=717
A 195 @35.7,10.8 id=715
C 188 @32.2,17.4 mobs=729
C 195 @31.7,23.5 mobs=686
T 188 @35.6,10.6 id=717
T 195 @35.7,10.8 id=715
T 189 @27.0,77.1 id=737
T 213 @27.0,77.1 id=737
T 605 @27.1,77.2 id=2498
T 210 @26.9,77.2 id=773
A 616 @26.9,77.2 id=773
A 627 @26.9,77.2 id=773
T 616 @27.2,76.9 id=2496
T 575 @28.3,77.6 id=2495
A 577 @28.3,77.6 id=2495
C 577 @41.1,17.2 mobs=1152
A 192 @35.5,10.6 id=718
A 207 @37.8,3.6 id=739
A 574 @38.0,3.3 id=733
C 574 @46.0,7.7 mobs=938,941
T 574 @38.0,3.0 id=469
C 207 @29.5,19.1
T 207 @37.8,3.6 id=739
C 192 @49.2,22.7 mobs=684
T 192 @35.5,10.6 id=718
T 577 @28.3,77.6 id=2495
L 37 "Tue des monstres autour de toi jusqu'au niveau 37"
A 339 @35.7,10.5 id=716
A 340 @35.7,10.5 id=716
A 341 @35.7,10.5 id=716
A 342 @35.7,10.5 id=716
A 205 @37.8,3.6 id=739
C 339 @24.2,10.3 mobs=667,696,780,1096,701
C 342 @23.8,10.5 mobs=667,696,780,1096,701
T 339 @35.7,10.5 id=716
T 342 @35.7,10.5 id=716
C 340 @46.7,40.1 mobs=667,696,780,1096,701
C 341 @46.2,40.0 mobs=667,696,780,1096,701
C 205 @47.4,39.4 mobs=780,670
T 340 @35.7,10.5 id=716
T 341 @35.7,10.5 id=716
T 205 @37.8,3.6 id=739
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-37-arathi",
    name = "Hautes-terres d'Arathi 37-39",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 37, maxLevel = 39,
    next = "alliance-nightelf-39-desolace",
    text = [[
M arathi
G "Rejoins Hautes-terres d'Arathi" @31.8,82.7 r=40 upto=41
A 663 @31.8,82.7 id=2766
T 663 @32.3,81.4 id=2610
A 662 @32.8,81.5 id=2767
A 664 @34.0,80.8 id=2769
C 662 @21.9,85.1
C 664 @21.9,86.6 mobs=2595,2596
T 662 @32.8,81.5 id=2767
T 664 @34.0,80.8 id=2769
T 659 @60.2,53.9 id=2712
A 658 @60.2,53.9 id=2712
C 658 @52.5,61.5 mobs=2714
T 658 @60.2,53.9 id=2712
A 657 @60.2,53.9 id=2712
T 657 @60.2,53.9 id=2713
A 642 @62.5,33.7
A 681 @45.8,47.6 id=2700
C 681 @32.2,29.1 mobs=2586,2589
T 681 @45.8,47.6 id=2700
C 627 @84.6,31.6
C 642 @84.2,32.9 mobs=2572,2574,2573
T 642 @84.3,30.9
A 651 @84.3,30.9
C 651 @25.6,30.4 mobs=2760
T 651 @36.2,57.4
L 39 "Tue des monstres autour de toi jusqu'au niveau 39"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-39-desolace",
    name = "Désolace 39-41",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 39, maxLevel = 41,
    next = "alliance-nightelf-41-dustwallow",
    text = [[
M desolace
G "Rejoins Désolace" @66.5,7.9 r=40 upto=43
A 261 @66.5,7.9 id=1182
A 1382 @66.7,10.9 id=5396
A 1385 @66.7,10.9 id=5396
A 1437 @66.4,11.8 id=5642
T 1437 @56.5,17.8
A 1465 @56.5,17.8
T 1465 @66.4,11.8 id=5642
A 1438 @66.4,11.8 id=5642
T 1438 @54.9,26.1 id=5644
A 1439 @54.9,26.1 id=5644
C 1439 @53.0,29.1 mobs=5643
T 1439 @54.9,26.1 id=5644
A 5501 @62.3,39.0 id=11438
C 5501 @52.8,59.1
T 5501 @62.3,39.0 id=11438
T 1385 @75.0,68.2 id=5398
C 261 @63.5,90.0 mobs=11561
T 1382 @36.2,79.2 id=5397
A 6161 @36.1,30.4
A 5741 @38.9,27.2 id=11863
C 6161 @29.0,9.3 mobs=11562,4714,11563,4711,4719
T 6161 @30.0,8.7
C 5741 @55.2,30.1 mobs=13019
T 5741 @38.9,27.2 id=11863
T 261 @66.5,7.9 id=1182
L 41 "Tue des monstres autour de toi jusqu'au niveau 41"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-41-dustwallow",
    name = "Marécage d'Âprefange 41-43",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 41, maxLevel = 43,
    next = "alliance-nightelf-43-badlands",
    text = [[
M dustwallow
G "Rejoins Marécage d'Âprefange" @29.8,48.2 r=40 upto=45
A 1252 @29.8,48.2
A 1253 @29.6,48.6
A 1284 @29.7,47.6
A 1177 @35.1,38.3 id=4503
A 1218 @55.4,26.3 id=4792
A 1219 @55.4,25.9
T 1218 @55.4,26.3 id=4792
A 1206 @55.4,26.3 id=4792
C 1177 @57.5,15.8 mobs=4359,4361,4362,4363,14230
T 1252 @68.2,48.6 id=4944
T 1253 @68.2,48.6 id=4944
T 1284 @68.2,48.6 id=4944
A 1259 @68.2,48.6 id=4944
A 1319 @68.2,48.6 id=4944
T 1259 @68.0,48.1 id=4948
A 1285 @68.0,48.1 id=4948
T 1285 @68.2,48.6 id=4944
A 1286 @68.2,48.6 id=4944
T 1219 @67.1,53.2 id=4947
A 1220 @67.1,53.2 id=4947
T 1319 @64.8,50.4 id=4941
A 1320 @64.8,50.4 id=4941
T 1220 @68.2,48.6 id=4944
T 1320 @68.2,48.6 id=4944
A 1282 @66.2,46.1 id=4921
T 1282 @68.2,48.6 id=4944
T 1286 @36.1,54.3 id=5089
A 1287 @36.1,54.3 id=5089
T 1177 @35.1,38.3 id=4503
C 1206 @32.0,21.9 mobs=4379,4376,4378,4380
T 1206 @55.4,26.3 id=4792
T 1287 @68.2,48.6 id=4944
L 43 "Tue des monstres autour de toi jusqu'au niveau 43"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-43-badlands",
    name = "Terres ingrates 43-44",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 43, maxLevel = 44,
    next = "alliance-nightelf-44-stv-2",
    text = [[
M badlands
G "Rejoins Terres ingrates" @42.4,52.9 r=40 upto=46
A 703 @42.4,52.9 id=2817
A 705 @42.4,52.9 id=2817
A 706 @53.8,43.3 id=2860
A 718 @53.8,43.3 id=2860
C 705 @41.5,29.8 mobs=2744
T 705 @42.4,52.9 id=2817
A 710 @25.9,44.9 id=2921
C 710 @20.4,44.6 mobs=2735
T 710 @25.9,44.9 id=2921
A 711 @25.9,44.9 id=2921
C 703 @16.2,60.1 mobs=4692,4693,5429,5428,2578
T 703 @42.4,52.9 id=2817
C 711 @42.9,81.7 mobs=92
T 711 @25.9,44.9 id=2921
A 712 @25.9,44.9 id=2921
C 712 @4.0,79.9 mobs=2736
T 712 @25.9,44.9 id=2921
C 718 @66.9,23.4
T 718 @53.8,43.3 id=2860
A 733 @53.8,43.3 id=2860
A 732 @61.9,54.3 id=2888
C 706 @82.9,32.8 mobs=2725
T 706 @53.8,43.3 id=2860
C 732 @12.6,75.5 mobs=2944
C 733 @10.9,76.5 mobs=2717,2720,2716,2718,2719
T 733 @53.8,43.3 id=2860
T 732 @61.9,54.3 id=2888
L 44 "Tue des monstres autour de toi jusqu'au niveau 44"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-44-stv-2",
    name = "Vallée de Strangleronce 44-47",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 44, maxLevel = 47,
    next = "alliance-nightelf-47-tanaris",
    text = [[
M stv
G "Rejoins Vallée de Strangleronce" @27.0,77.1 r=40 upto=49
T 627 @26.9,77.2 id=773
A 209 @27.0,77.1 id=737
A 600 @27.1,77.2 id=2498
A 617 @26.8,76.4 id=2494
A 621 @27.1,77.2 id=2498
A 2864 @26.9,77.2 id=773
A 595 @28.1,76.2 id=2490
A 606 @27.8,77.1 id=2501
A 2872 @27.8,77.1 id=2501
T 595 @27.3,69.5
A 597 @27.3,69.5
T 597 @28.1,76.2 id=2490
A 576 @28.6,75.9 id=2493
A 599 @28.1,76.2 id=2490
T 599 @27.2,77.0 id=2487
A 587 @26.9,77.3 id=2488
A 604 @27.2,77.0 id=2487
C 604 @27.4,82.8 mobs=1563
T 604 @27.2,77.0 id=2487
A 608 @27.2,77.0 id=2487
C 576 @30.0,89.3 mobs=1565,1653,1564,1563,4505
C 587 @30.0,89.3 mobs=1565,1653,1564,1563,4505
C 608 @32.9,88.2 mobs=2550,2548,2546
T 576 @28.6,75.9 id=2493
T 587 @26.9,77.3 id=2488
T 608 @27.2,77.0 id=2487
C 606 @33.2,66.0 mobs=1557
C 617 @27.1,62.2 mobs=1907
T 606 @26.9,73.6 id=2502
A 607 @26.9,73.6 id=2502
T 617 @26.8,76.4 id=2494
T 607 @27.8,77.1 id=2501
A 609 @27.8,77.1 id=2501
C 621 @39.7,58.3 mobs=1491,1488,1490,1489,2534
C 609 @35.1,51.6 mobs=2535,2536,2537
C 600 @41.7,43.7 mobs=674,14492,677,676,675
C 209 @46.4,40.1 mobs=667,696,780,783,669
A 196 @35.7,10.8 id=715
C 196 @31.1,42.7 mobs=687
T 196 @35.7,10.8 id=715
T 600 @27.1,77.2 id=2498
T 621 @27.1,77.2 id=2498
T 609 @27.8,77.1 id=2501
T 209 @27.0,77.1 id=737
L 47 "Tue des monstres autour de toi jusqu'au niveau 47"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-47-tanaris",
    name = "Tanaris 47-49",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 47, maxLevel = 49,
    next = "alliance-nightelf-49-feralas",
    text = [[
M tanaris
G "Rejoins Tanaris" @52.5,28.5 r=40 upto=51
A 1690 @52.5,28.5 id=7407
A 1707 @52.5,28.4 id=7408
A 2605 @51.8,28.7 id=7564
T 2864 @51.6,26.8 id=7876
A 2781 @51.8,27.0
A 3362 @51.6,26.8 id=7876
A 5863 @52.8,27.4 id=11758
C 1690 @63.5,31.3 mobs=5616,5618
C 1707 @63.5,31.3 mobs=5616,5617,5615,5618,5623
C 2781 @61.8,38.2 mobs=7847
T 2872 @67.1,24.0 id=7881
A 2873 @67.1,24.0 id=7881
A 8366 @67.1,23.9 id=7882
A 2875 @66.8,22.3
A 8365 @66.6,22.3 id=15165
T 1690 @52.5,28.5 id=7407
T 1707 @52.5,28.4 id=7408
T 2781 @52.5,28.5 id=7407
A 1691 @52.5,28.5 id=7407
C 1691 @59.8,37.8 mobs=5617,5615,5623
T 1691 @52.5,28.5 id=7407
A 3161 @52.7,45.9 id=7771
C 5863 @40.8,52.5 mobs=5474,5472,12046
C 3161 @47.1,65.2
T 3161 @52.7,45.9 id=7771
T 5863 @52.8,27.4 id=11758
C 2873 @72.2,46.8
C 8366 @73.5,47.2 mobs=7858,7857,7856,7855
C 2875 @73.4,47.1 mobs=7883
C 8365 @73.5,47.2 mobs=7858,7857,7856,7855,7883
T 2873 @67.1,24.0 id=7881
T 8366 @67.1,23.9 id=7882
T 2875 @67.1,23.9 id=7882
T 8365 @66.6,22.3 id=15165
C 2605 @29.7,66.0 mobs=5481
C 3362 @29.6,66.0 mobs=5485,5490
T 2605 @51.8,28.7 id=7564
A 2606 @51.8,28.7 id=7564
T 3362 @51.6,26.8 id=7876
T 2606 @51.1,26.9 id=7583
L 49 "Tue des monstres autour de toi jusqu'au niveau 49"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-49-feralas",
    name = "Féralas 49-50",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 49, maxLevel = 50,
    next = "alliance-nightelf-50-hinterlands",
    text = [[
M feralas
G "Rejoins Féralas" @30.3,46.2 r=40 upto=52
A 2866 @30.3,46.2 id=3936
A 4124 @30.4,46.2 id=7877
T 4124 @31.9,45.1 id=7880
A 2982 @31.8,45.6 id=7900
A 4125 @31.9,45.1 id=7880
A 2821 @30.6,42.7 id=7852
T 2866 @26.3,52.3
A 2867 @26.3,52.3
T 2867 @30.3,46.2 id=3936
A 3130 @30.3,46.2 id=3936
T 3130 @30.4,46.2 id=7877
A 2869 @30.4,46.2 id=7877
C 2869 @27.4,68.9 mobs=5336,5333,5335,5331,5334
T 2869 @30.4,46.2 id=7877
A 2870 @30.4,46.2 id=7877
A 7721 @44.8,43.4 id=14637
C 7721 @47.7,52.3 mobs=5462,5461
T 7721 @44.8,43.4 id=14637
T 4125 @45.4,65.0
A 4127 @45.4,65.0
C 2821 @51.8,58.9 mobs=5292,5293,5295,5346
C 2982 @60.8,56.3 mobs=5232,5240,5236
T 2982 @31.8,45.6 id=7900
T 4127 @31.9,45.1 id=7880
A 4129 @31.9,45.1 id=7880
T 4129 @32.5,43.8 id=7879
A 4130 @32.5,43.8 id=7879
T 4130 @31.9,45.1 id=7880
A 4131 @31.9,45.1 id=7880
T 2821 @30.6,42.7 id=7852
A 7733 @30.6,42.7 id=7852
C 2870 @28.5,70.5 mobs=8136
T 2870 @30.4,46.2 id=7877
A 2871 @30.4,46.2 id=7877
T 2871 @30.1,45.1 id=7878
A 2844 @42.4,22.0 id=7765
T 2844 @38.2,10.3 id=7774
C 7733 @53.8,32.1 mobs=5299,5296,5297
T 7733 @30.6,42.7 id=7852
T 4131 @73.3,56.3
A 4135 @73.3,56.3
T 4135 @72.1,63.7
L 50 "Tue des monstres autour de toi jusqu'au niveau 50"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-50-hinterlands",
    name = "Les Hinterlands 50-52",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 50, maxLevel = 52,
    next = "alliance-nightelf-52-searing",
    text = [[
M hinterlands
G "Rejoins Les Hinterlands" @14.8,44.6 r=40 upto=54
A 2877 @14.8,44.6 id=7884
A 2880 @14.8,44.6 id=7884
A 2988 @9.8,44.5 id=5636
C 2988 @23.2,58.8
C 2880 @31.0,58.4 mobs=4466,4467,2653,2651,2649
T 2880 @14.8,44.6 id=7884
T 2988 @9.8,44.5 id=5636
C 2877 @57.7,42.5 mobs=2655,2656
T 2877 @14.8,44.6 id=7884
L 52 "Tue des monstres autour de toi jusqu'au niveau 52"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-52-searing",
    name = "Gorge des Vents brûlants 52-53",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 52, maxLevel = 53,
    next = "alliance-nightelf-53-ungoro",
    text = [[
M searing
G "Rejoins Gorge des Vents brûlants" @38.8,28.5 r=40 upto=55
A 7722 @38.8,28.5 id=14624
A 7723 @38.6,27.8 id=14627
A 7724 @38.6,27.8 id=14627
A 7727 @38.6,27.8 id=14627
A 7728 @37.6,26.5
A 7729 @37.6,26.5
C 7722 @40.5,35.7
C 7729 @42.9,34.0 mobs=5846,5844
T 7722 @38.8,28.5 id=14624
T 7729 @39.0,27.5 id=14626
C 7727 @47.7,25.4 mobs=9318
T 7727 @38.6,27.8 id=14627
C 7723 @36.7,44.8 mobs=5854
C 7728 @38.0,50.9 mobs=8566,5840
C 7724 @28.6,44.4 mobs=5858
T 7723 @38.6,27.8 id=14627
T 7724 @38.6,27.8 id=14627
T 7728 @39.0,27.5 id=14626
L 53 "Tue des monstres autour de toi jusqu'au niveau 53"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-53-ungoro",
    name = "Cratère d'Un'Goro 53-55",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 53, maxLevel = 55,
    next = "alliance-nightelf-55-azshara",
    text = [[
M ungoro
G "Rejoins Cratère d'Un'Goro" @44.0,7.1 r=40 upto=57
A 3881 @44.0,7.1 id=9270
A 3882 @43.5,7.4 id=9272
A 4492 @43.6,8.5 id=9997
A 4501 @43.5,8.4
A 4141 @42.9,9.6 id=9119
A 4503 @44.2,11.6 id=9998
A 4243 @46.4,13.4 id=9618
A 4284 @41.9,2.7 id=9117
T 4243 @67.7,16.8 id=9623
C 4284 @67.2,15.6 mobs=6510,9167,9164,6512,9163
C 4141 @66.8,30.3 mobs=6510,6512,6511,6509
C 3881 @68.5,36.5
T 4492 @51.9,49.9 id=9999
C 4503 @53.1,62.6 mobs=9167,9164,9163,9166,9165
A 3844 @63.0,68.6
T 3844 @63.1,69.1
A 4289 @71.6,76.0 id=9619
A 4290 @71.6,76.0 id=9619
C 4290 @68.7,56.7
T 4290 @71.6,76.0 id=9619
C 3882 @32.2,74.7 mobs=9164,9163,9162
A 974 @30.9,50.4 id=10302
C 4501 @22.8,40.3 mobs=9167,9166
T 4501 @43.6,8.5 id=9997
T 4141 @42.9,9.6 id=9119
T 3881 @44.0,7.1 id=9270
T 3882 @43.5,7.4 id=9272
T 4503 @44.2,11.6 id=9998
T 4284 @41.9,2.7 id=9117
C 4289 @66.8,15.7 mobs=6514,6513,6516
C 974 @54.0,55.2 mobs=10541
T 4289 @71.6,76.0 id=9619
A 4301 @71.6,76.0 id=9619
T 974 @30.9,50.4 id=10302
A 980 @30.9,50.4 id=10302
C 4301 @68.1,12.6 mobs=9622
T 4301 @71.6,76.0 id=9619
L 55 "Tue des monstres autour de toi jusqu'au niveau 55"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-55-azshara",
    name = "Azshara 55-56",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 55, maxLevel = 56,
    next = "alliance-nightelf-56-felwood",
    text = [[
M azshara
G "Rejoins Azshara" @53.5,21.8 r=40 upto=58
A 3601 @53.5,21.8 id=8420
C 3601 @58.2,29.6
T 3601 @53.5,21.8 id=8420
A 5534 @53.5,21.8 id=8420
C 5534 @47.1,49.9 mobs=6195,6196,7885,7886
T 5534 @53.5,21.8 id=8420
L 56 "Tue des monstres autour de toi jusqu'au niveau 56"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-56-felwood",
    name = "Gangrebois 56-57",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 56, maxLevel = 57,
    next = "alliance-nightelf-57-burning",
    text = [[
M felwood
G "Rejoins Gangrebois" @51.4,81.5 r=40 upto=59
A 4421 @51.4,81.5 id=9116
A 5155 @51.2,82.1 id=10922
A 5156 @50.9,81.6 id=10921
A 5249 @51.0,81.6 id=10924
A 4101 @54.1,86.8 id=9528
C 4421 @37.1,67.9 mobs=7109,7110,7106,9454
C 5155 @37.8,61.1 mobs=7113,7112,7115,7125
C 5156 @41.8,39.9 mobs=9878,9879
C 4101 @58.2,20.2 mobs=7100,7101
A 8461 @64.8,8.1 id=15395
C 8461 @62.4,9.2 mobs=7157,7158,7156
T 8461 @64.8,8.1 id=15395
A 8465 @64.8,8.1 id=15395
T 4421 @51.4,81.5 id=9116
T 5155 @51.2,82.1 id=10922
T 5156 @50.9,81.6 id=10921
A 4906 @51.4,81.5 id=9116
T 4101 @54.1,86.8 id=9528
A 4103 @54.1,86.8 id=9528
C 4103 @38.8,47.6 mobs=8959,8960,8956,8958,8957
C 4906 @42.6,16.8 mobs=7107,7111,7108,10648
T 4906 @51.4,81.5 id=9116
T 4103 @54.1,86.8 id=9528
L 57 "Tue des monstres autour de toi jusqu'au niveau 57"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-57-burning",
    name = "Steppes ardentes 57-58",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 57, maxLevel = 58,
    next = "alliance-nightelf-57-winterspring",
    text = [[
M burning
G "Rejoins Steppes ardentes" @84.6,68.7 r=40 upto=59
A 3823 @84.6,68.7 id=9177
A 4283 @84.6,68.7 id=9177
C 3823 @80.4,44.2 mobs=7033,7034,7035
T 3823 @84.6,68.7 id=9177
A 3824 @84.6,68.7 id=9177
C 3824 @39.3,55.3 mobs=9176
C 4283 @41.3,34.7 mobs=7027,7028,7025,7026,7029
T 4283 @84.6,68.7 id=9177
T 3824 @84.6,68.7 id=9177
A 3825 @84.6,68.7 id=9177
C 3825 @81.0,46.8
T 3825 @84.6,68.7 id=9177
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-57-winterspring",
    name = "Berceau-de-l'Hiver 57-59",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 57, maxLevel = 59,
    next = "alliance-nightelf-59-wpl",
    text = [[
M winterspring
G "Rejoins Berceau-de-l'Hiver" @61.9,38.3 r=40 upto=61
A 969 @61.9,38.3 id=10307
A 5601 @61.3,39.0 id=11629
A 6028 @61.4,39.0 id=10431
A 6030 @61.4,39.0 id=10431
A 6604 @61.1,38.4 id=11755
A 6606 @61.1,38.4 id=11755
T 6606 @61.9,38.3 id=10307
A 3783 @60.9,37.6 id=10305
A 6603 @60.7,38.2 id=11754
C 3783 @66.7,43.2 mobs=7458,7457
T 3783 @60.9,37.6 id=10305
A 977 @60.9,37.6 id=10305
T 5249 @52.0,30.4 id=11079
T 6604 @52.1,30.4 id=10301
A 4861 @52.1,30.4 id=10301
A 5244 @52.0,30.4 id=11079
T 5244 @52.1,30.4 id=10301
A 5245 @52.1,30.4 id=10301
C 5245 @52.2,42.2
T 4861 @59.0,59.8
A 4863 @59.0,59.8
T 4863 @61.4,60.7
A 4864 @61.4,60.7
C 969 @59.8,67.2
T 969 @61.9,38.3 id=10307
C 977 @70.5,40.0 mobs=7459,7460
T 977 @60.9,37.6 id=10305
C 4864 @64.5,22.0 mobs=7453,7452,7454
T 4864 @52.1,30.4 id=10301
T 980 @31.3,45.2 id=9298
T 6603 @31.3,45.2 id=9298
A 5082 @31.3,45.2 id=9298
T 8465 @27.7,34.5 id=11556
A 8464 @27.7,34.5 id=11556
C 5082 @40.6,43.5 mobs=7442,7440,7441
T 5082 @31.3,45.2 id=9298
C 8464 @67.2,36.0 mobs=7440,7438,7439
T 8464 @27.7,34.5 id=11556
L 59 "Tue des monstres autour de toi jusqu'au niveau 59"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-59-wpl",
    name = "Maleterres de l'Ouest 59-60",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 59, maxLevel = 60,
    next = "alliance-nightelf-60-epl",
    text = [[
M wpl
G "Rejoins Maleterres de l'Ouest" @43.0,83.5 r=40 upto=62
T 6028 @43.0,83.5 id=10840
A 5401 @43.0,83.5 id=10840
T 5401 @43.0,83.5 id=10840
A 4984 @53.7,64.7 id=10739
A 5058 @47.8,50.7
T 5058 @47.8,50.7
C 4984 @45.8,45.9 mobs=1817
T 4984 @53.7,64.7 id=10739
A 4985 @53.7,64.7 id=10739
C 4985 @64.5,48.1 mobs=1816
T 4985 @53.7,64.7 id=10739
A 6004 @51.9,28.1 id=11610
C 6004 @51.2,42.7 mobs=1833,1831,10605,1826
T 6004 @51.9,28.1 id=11610
A 6023 @51.9,28.1 id=11610
C 6023 @57.8,36.1 mobs=11613,11611
T 6023 @51.9,28.1 id=11610
L 60 "Tue des monstres autour de toi jusqu'au niveau 60"
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-60-epl",
    name = "Maleterres de l'Est 60-61",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 60, maxLevel = 61,
    next = "alliance-nightelf-60-silithus",
    text = [[
M epl
G "Rejoins Maleterres de l'Est" @71.5,49.7 r=40 upto=62
T 6030 @71.6,50.1 id=11039
A 9124 @71.7,48.9 id=16132
A 9126 @71.6,48.9 id=16131
A 9128 @71.7,48.7 id=16116
A 9664 @71.5,49.7 id=17069
A 5281 @69.9,53.7 id=11038
A 6021 @69.9,53.7 id=11038
C 9126 @58.7,31.1 mobs=1789,1783,1787,1784,8523
T 5245 @46.5,16.0 id=10304
T 9126 @71.6,48.9 id=16131
C 9128 @53.6,68.5 mobs=11744,11746,6521,9878,9879
T 9128 @71.7,48.7 id=16116
T 5601 @31.1,78.0 id=10926
A 6024 @22.9,73.0
C 6021 @23.1,72.6 mobs=12250
C 9664 @34.1,64.1 mobs=17689,17690,17696,17698
T 5281 @11.4,26.6 id=11140
A 6164 @11.4,26.4 id=12384
C 9124 @8.4,27.6 mobs=8558,8555,8557,8556
C 6164 @14.0,24.2
T 6164 @11.4,26.4 id=12384
A 5542 @5.2,35.6 id=1855
A 5543 @5.2,35.6 id=1855
A 5544 @5.2,35.6 id=1855
C 5543 @13.9,66.6 mobs=8600
T 5543 @5.2,35.6 id=1855
C 5542 @44.4,31.3 mobs=8598,8596,8597
C 5544 @56.3,23.0 mobs=8603,8605
C 6024 @62.0,11.1 mobs=12248
T 9124 @71.7,48.9 id=16132
T 9664 @71.5,49.7 id=17069
T 6021 @69.9,53.7 id=11038
T 6024 @23.6,73.8
T 5542 @5.2,35.6 id=1855
T 5544 @5.2,35.6 id=1855
]],
})

ns.RegisterGuide({
    id = "alliance-nightelf-60-silithus",
    name = "Silithus 60-61",
    faction = "Alliance", race = { NightElf = true }, path = "alliance-nightelf",
    minLevel = 60, maxLevel = 61,
    text = [[
M silithus
G "Rejoins Silithus" @51.6,38.6 r=40 upto=62
A 8277 @51.6,38.6 id=15189
A 8280 @51.1,38.3 id=15191
A 8284 @49.7,37.5 id=15183
A 8318 @48.6,37.8 id=15306
A 8320 @48.6,37.9 id=15270
A 8800 @50.0,36.4 id=15540
T 8800 @51.2,38.9 id=15176
A 9415 @50.7,34.7 id=17082
A 8304 @49.2,34.2 id=15181
C 8318 @39.4,44.5 mobs=11880,11881,11882,15213,15201
T 9415 @33.3,51.1 id=17080
A 9419 @33.3,51.1 id=17080
C 9419 @33.0,50.8 mobs=17090
T 9419 @33.3,51.1 id=17080
C 8320 @26.4,34.7 mobs=11881
C 8284 @22.1,10.4 mobs=14455
T 8284 @49.7,37.5 id=15183
T 8318 @48.6,37.8 id=15306
T 8320 @48.6,37.9 id=15270
A 8285 @49.7,37.5 id=15183
A 8321 @48.6,37.9 id=15270
C 8280 @53.4,17.3 mobs=11740
C 8277 @60.7,21.9 mobs=11735,11738
T 8277 @51.6,38.6 id=15189
T 8280 @51.1,38.3 id=15191
A 8278 @51.6,38.6 id=15189
A 8281 @51.1,38.3 id=15191
C 8281 @30.2,42.8 mobs=11741
T 8281 @51.1,38.3 id=15191
T 8285 @67.2,69.8 id=15194
A 8279 @67.2,69.8 id=15194
C 8304 @41.0,89.0 mobs=15221,15222
C 8278 @33.6,75.5 mobs=11736,11737,11739
T 8278 @51.6,38.6 id=15189
A 8282 @51.6,38.5 id=15190
T 8304 @49.2,34.2 id=15181
C 8279 @26.4,36.6 mobs=15200,11803,11804
T 8279 @67.2,69.8 id=15194
A 8287 @67.2,69.8 id=15194
A 8323 @67.2,69.8 id=15194
T 8287 @49.2,34.2 id=15181
C 8323 @39.4,44.5 mobs=11880,11881,11882,15213,15201
T 8323 @67.2,69.8 id=15194
C 8282 @44.6,91.4
T 8282 @51.6,38.5 id=15190
C 8321 @72.4,15.6 mobs=15202
T 8321 @48.6,37.9 id=15270
]],
})
