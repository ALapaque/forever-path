local _, ns = ...

-- GÉNÉRÉ AUTOMATIQUEMENT par tools/gen_routes.py à partir de QuestieDB (Forever).
-- Ne pas modifier à la main : régénérer. Parcours : horde-orc

ns.RegisterGuide({
    id = "horde-orc-01-durotar",
    name = "Durotar 1-11",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 1, maxLevel = 11,
    next = "horde-orc-11-barrens",
    text = [[
M durotar
G "Rejoins Durotar" @42.1,68.3 r=40 upto=13
A 788 @42.1,68.3 id=3143 lvl=2
A 4641 @43.3,68.5 race=Orc,Troll id=10176 lvl=1
T 4641 @42.1,68.3 race=Orc,Troll id=3143
C 788 @43.9,62.5 mobs=3098
A 790 @40.6,62.6 id=3287 lvl=5
T 788 @42.1,68.3 id=3143
A 789 @42.1,68.3 id=3143 lvl=3
C 790 @40.5,66.8 mobs=3281
T 790 @40.6,62.6 id=3287
A 804 @40.6,62.6 id=3287 lvl=5
C 789 @40.6,63.9 mobs=3124,3281
T 789 @42.1,68.3 id=3143
T 804 @42.1,68.3 id=3143
A 4402 @42.7,67.2 id=9796 lvl=3
A 5441 @44.6,68.7 id=11378 lvl=4
C 4402 @45.4,61.5
C 5441 @42.7,58.0 mobs=10556
T 4402 @42.7,67.2 id=9796
T 5441 @44.6,68.7 id=11378
A 6394 @44.6,68.7 id=11378 lvl=4
A 2161 @52.1,68.3 id=6786 lvl=5
A 786 @54.2,73.3 id=3140 lvl=8
A 817 @56.0,73.9 id=3194 lvl=8
A 818 @55.9,74.4 id=3304 lvl=7 danger=1
A 823 @56.0,74.7 id=3188 lvl=7
C 818 @54.0,82.8 mobs=3107,3106,3103,6020,3104 danger=1
T 818 @55.9,74.4 id=3304 danger=1
A 808 @56.0,74.7 id=3188 lvl=9
C 786 @46.9,78.1
T 786 @54.2,73.3 id=3140
C 817 @68.9,72.4 mobs=3121
C 808 @67.4,87.8
T 817 @56.0,73.9 id=3194
T 808 @56.0,74.7 id=3188
A 826 @56.0,74.7 id=3188 lvl=10 danger=1
C 826 @67.4,85.0 mobs=3207,3206,3205 danger=1
T 826 @56.0,74.7 id=3188 danger=1
C 6394 @43.7,53.8
T 6394 @44.6,68.7 id=11378
B "Lie ta pierre de foyer à l'auberge" @51.5,41.6 id=6928
T 2161 @51.5,41.6 id=6928
T 823 @52.2,43.1 id=3142
A 784 @52.0,43.5 id=3139 lvl=7
A 815 @51.1,42.5 id=3191 lvl=8
A 837 @52.0,43.5 id=3139 lvl=10
A 791 @49.9,40.4 id=3147 lvl=7
C 837 @43.1,38.9 mobs=3114,3112,3113,3111
A 816 @43.1,30.2 id=3193 lvl=11
A 834 @46.4,22.9 id=3293 lvl=9
C 834 @48.2,32.5
T 834 @46.4,22.9 id=3293
A 835 @46.4,22.9 id=3293 lvl=11
C 835 @52.3,22.1 mobs=3118,3117
T 835 @46.4,22.9 id=3293
H "Utilise ta pierre de foyer" @51.5,41.6 id=6928
T 837 @52.0,43.5 id=3139
A 806 @52.2,43.1 id=3142 lvl=12
C 784 @58.5,57.0 mobs=3128,3129,3192
C 791 @58.5,57.1 mobs=3128,3129,3119,3120,5808
T 784 @52.0,43.5 id=3139
A 825 @52.0,43.5 id=3139 lvl=8
A 840 @50.8,43.6 id=3336 lvl=12
T 791 @49.9,40.4 id=3147
C 806 @42.1,26.7 mobs=3203
T 806 @52.2,43.1 id=3142
A 828 @52.2,43.1 id=3142 lvl=12
C 825 @63.2,55.5
C 815 @68.6,71.5
T 815 @51.1,42.5 id=3191
T 825 @52.0,43.5 id=3139
T 828 @56.4,20.0 id=3208
A 827 @56.4,20.0 id=3208 lvl=12
C 827 @52.9,9.3 mobs=3197,3198,3199,3195,3196
T 827 @56.4,20.0 id=3208
C 816 @35.0,54.8 mobs=3110,3231
T 816 @43.1,30.2 id=3193
]],
})

ns.RegisterGuide({
    id = "horde-orc-11-barrens",
    name = "Les Tarides 11-19",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 11, maxLevel = 19,
    next = "horde-orc-19-silverpine",
    text = [[
M barrens
G "Rejoins Les Tarides" @52.2,31.0 r=40 upto=21
B "Lie ta pierre de foyer à l'auberge" @52.0,29.9 id=3934
A 844 @52.2,31.0 id=3338 lvl=12 danger=1
A 869 @51.9,30.3 id=3464 lvl=13 danger=1
A 871 @51.5,30.9 id=3429 lvl=12
A 1492 @51.4,30.1 id=3390 lvl=11
A 6365 @52.6,29.8 race=Orc,Troll id=3489 lvl=10
T 6365 @51.5,30.3 race=Orc,Troll id=3615
C 871 @55.0,26.1 mobs=3267,3268,3265
C 844 @57.3,30.5 mobs=3246,3244,3245 danger=1
T 844 @52.2,31.0 id=3338 danger=1
T 871 @51.5,30.9 id=3429
A 845 @52.2,31.0 id=3338 lvl=13 danger=1
A 848 @51.4,30.1 id=3390 lvl=15
A 867 @51.6,30.9 id=3449 lvl=15 danger=1
A 872 @51.5,30.9 id=3429 lvl=15
A 5041 @51.5,30.9 id=3429 lvl=14
C 845 @52.5,36.4 mobs=3242,3426,3466 danger=1
T 845 @52.2,31.0 id=3338 danger=1
A 903 @52.2,31.0 id=3338 lvl=15
A 855 @45.3,28.4 id=3389 lvl=14
C 848 @45.1,22.8
C 867 @40.6,15.8 mobs=3278,3276,3280,3277,3279 danger=1
A 850 @45.3,28.4 id=3389 lvl=16 danger=1
C 850 @42.8,23.5 mobs=3394 danger=1
T 850 @45.3,28.4 id=3389 danger=1
T 848 @51.4,30.1 id=3390
T 867 @51.6,30.9 id=3449 danger=1
A 875 @51.6,30.9 id=3449 lvl=16 danger=1
C 872 @59.2,25.0 mobs=3266,3269,3438
C 5041 @58.9,25.9
T 840 @62.3,19.4 id=3337
A 842 @62.3,19.4 id=3337 lvl=12
C 903 @54.0,15.0 mobs=3425
H "Utilise ta pierre de foyer" @52.0,29.9 id=3934
T 872 @51.5,30.9 id=3429
T 5041 @51.5,30.9 id=3429
T 903 @52.2,31.0 id=3338
T 842 @52.2,31.0 id=3338
C 855 @45.0,38.7 mobs=3272,3273,3397,3275,3274
T 855 @45.3,28.4 id=3389
C 875 @39.2,15.7 mobs=3278 danger=1
T 875 @51.6,30.9 id=3449 danger=1
A 887 @62.7,36.2 id=3391 lvl=14
A 894 @63.0,37.2 id=3442 lvl=14
A 895 @62.6,37.5 lvl=16
T 1492 @63.4,38.5 id=3453
C 887 @63.9,45.4 mobs=3381,3382
C 895 @63.1,49.4 mobs=3467
C 869 @59.3,45.6 mobs=3255,3256,3254 danger=1
T 887 @62.7,36.2 id=3391
T 895 @62.7,36.2 id=3391
A 865 @62.4,37.6 id=3446 lvl=18 danger=1
A 890 @62.7,36.2 id=3391 lvl=14
T 890 @63.4,38.5 id=3453
A 892 @63.4,38.5 id=3453 lvl=14
A 896 @63.4,38.5 id=3453 lvl=18 danger=1
T 892 @62.7,36.2 id=3391
A 888 @62.7,36.2 id=3391 lvl=16
C 888 @63.1,49.4
C 865 @57.4,53.5 mobs=3256 danger=1
T 865 @62.4,37.6 id=3446 danger=1
T 888 @62.7,36.2 id=3391
T 869 @51.9,30.3 id=3464 danger=1
A 3281 @51.9,30.3 id=3464 lvl=18
T 894 @52.4,11.7
A 900 @52.4,11.7 lvl=14
C 900 @52.3,11.5
T 900 @52.4,11.7
A 901 @52.4,11.7 lvl=14
C 901 @52.8,10.4 mobs=3471
T 901 @52.4,11.7
A 902 @52.4,11.7 lvl=16
A 858 @56.5,7.5 id=3439 lvl=18
C 858 @56.3,8.6 mobs=3445
T 858 @56.5,7.5 id=3439
C 896 @60.7,3.9 mobs=3283,3286,9336 danger=1
T 896 @63.4,38.5 id=3453 danger=1
T 902 @63.0,37.2 id=3442
A 1069 @62.4,37.6 id=3446 lvl=20
A 3921 @63.0,37.2 id=3442 lvl=14
A 891 @62.3,39.0 id=3339 lvl=20 danger=1
H "Utilise ta pierre de foyer" @52.0,29.9 id=3934
A 876 @51.6,30.9 id=3449 lvl=20
A 6541 @51.5,30.9 id=3429 lvl=19
A 899 @52.0,31.6 id=3432 lvl=20 danger=1
A 4921 @52.0,31.6 id=3432 lvl=20
C 4921 @49.3,50.3 mobs=10668
C 899 @52.9,53.5 mobs=3258,3263,3260,3261 danger=1
C 3281 @58.0,53.9
C 891 @61.5,54.6 mobs=3385,3386,3393,3455,3454 danger=1
T 891 @62.3,39.0 id=3339 danger=1
T 3281 @51.9,30.3 id=3464
T 899 @52.0,31.6 id=3432 danger=1
T 4921 @52.0,31.6 id=3432
T 3921 @49.0,11.2 id=9316
A 3922 @49.0,11.2 id=9316 lvl=15
T 6541 @48.1,5.4 id=8582
C 3922 @56.3,8.3
T 3922 @49.0,11.2 id=9316
C 876 @39.2,12.2 mobs=3452
A 1062 @35.3,27.9 id=4049 lvl=19
A 6548 @35.2,27.8 id=11857 lvl=18
T 876 @51.6,30.9 id=3449
A 1060 @51.6,30.9 id=3449 lvl=20
A 1483 @63.0,37.2 id=3442 lvl=21
A 878 @44.5,59.3 id=3430 lvl=21
C 878 @53.1,53.3 mobs=3263,3260,3261
T 878 @44.5,59.3 id=3430
A 5052 @44.5,59.3 id=3430 lvl=21
C 5052 @52.0,54.3 mobs=3258,3461,3263,3260,3261
T 5052 @44.5,59.3 id=3430
L 19 "Tue des monstres autour de toi jusqu'au niveau 19"
H "Utilise ta pierre de foyer" @52.0,29.9 id=3934
A 868 @51.1,29.6 id=3428 lvl=22 danger=1
C 868 @43.1,70.8 mobs=3252,3250,3251,3503 danger=1
T 868 @51.1,29.6 id=3428 danger=1
]],
})

ns.RegisterGuide({
    id = "horde-orc-19-silverpine",
    name = "Forêt des Pins-Argentés 19-21",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 19, maxLevel = 21,
    next = "horde-orc-21-barrens-2",
    text = [[
M silverpine
G "Rejoins Forêt des Pins-Argentés" @43.4,40.9 r=40 upto=23
A 428 @43.4,40.9 id=1952 lvl=12
A 477 @44.0,40.9 id=2121 lvl=14
A 493 @42.8,40.9 id=1937 lvl=20
A 516 @44.0,40.9 id=2121 lvl=21
T 477 @49.9,60.3
A 478 @49.9,60.3 lvl=14
C 516 @58.7,71.2 mobs=1973,1974
T 516 @44.0,40.9 id=2121
T 478 @44.0,40.9 id=2121
A 481 @44.0,40.9 id=2121 lvl=14
T 481 @44.2,39.8 id=1938
A 482 @44.2,39.8 id=1938 lvl=14
T 482 @44.0,40.9 id=2121
A 479 @44.0,40.9 id=2121 lvl=16
T 428 @53.5,13.4 id=1950
A 429 @53.5,13.4 id=1950 lvl=11
C 429 @66.8,7.0 mobs=1766,1765,1923,12431
T 429 @42.8,40.9 id=1937
A 430 @42.8,40.9 id=1937 lvl=11
T 430 @53.4,12.6 id=1951
A 425 @53.5,13.4 id=1950 lvl=12
C 425 @51.5,13.9 mobs=1971
T 425 @53.5,13.4 id=1950
C 479 @60.8,64.4 mobs=1912,1914,1915
T 479 @44.0,40.9 id=2121
A 480 @44.0,40.9 id=2121 lvl=22 danger=1
C 480 @63.4,64.3 mobs=2120 danger=1
T 480 @44.0,40.9 id=2121 danger=1
L 21 "Tue des monstres autour de toi jusqu'au niveau 21"
]],
})

ns.RegisterGuide({
    id = "horde-orc-21-barrens-2",
    name = "Les Tarides 21-24",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 21, maxLevel = 24,
    next = "horde-orc-24-stonetalon",
    text = [[
M barrens
H "Utilise ta pierre de foyer" @52.0,29.9 id=3934
A 893 @45.1,57.7 id=3433 lvl=24 danger=1
A 6382 @44.9,59.1 id=3387 lvl=20
A 843 @45.9,77.0 id=3341 lvl=23 danger=1
C 893 @43.5,82.8 mobs=3457,3458,3459,3456 danger=1
C 843 @47.6,85.2 mobs=3374,3375,3392 danger=1
T 843 @45.9,77.0 id=3341 danger=1
T 893 @45.1,57.7 id=3433 danger=1
L 22 "Tue des monstres autour de toi jusqu'au niveau 22"
A 879 @44.5,59.3 id=3430 lvl=25 danger=1
C 879 @45.1,80.1 mobs=3436,3434,3435 danger=1
T 879 @44.5,59.3 id=3430 danger=1
A 906 @44.5,59.3 id=3430 lvl=25
H "Utilise ta pierre de foyer" @52.0,29.9 id=3934
T 906 @51.5,30.9 id=3429
L 23 "Tue des monstres autour de toi jusqu'au niveau 23"
A 846 @45.9,77.0 id=3341 lvl=26 danger=1
C 846 @49.2,84.2 mobs=3376,3377,3378,6668 danger=1
T 846 @45.9,77.0 id=3341 danger=1
A 849 @45.9,77.0 id=3341 lvl=26
C 849 @47.0,85.6
T 849 @45.9,77.0 id=3341
L 24 "Tue des monstres autour de toi jusqu'au niveau 24"
]],
})

ns.RegisterGuide({
    id = "horde-orc-24-stonetalon",
    name = "Les Serres-Rocheuses 24-26",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 24, maxLevel = 26,
    next = "horde-orc-26-ashenvale",
    text = [[
M stonetalon
G "Rejoins Les Serres-Rocheuses" @45.9,60.4 r=40 upto=28
A 1087 @45.9,60.4 id=4198 lvl=25
A 6282 @47.2,61.2 id=11860 lvl=26
A 6301 @47.5,58.4 id=11864 lvl=23
A 6393 @47.4,64.2 id=11862 lvl=25 danger=1
A 6562 @47.4,64.2 id=11862 lvl=22
C 1069 @53.4,73.5
T 1483 @59.0,62.6 id=4201
A 1093 @59.0,62.6 id=4201 lvl=21
C 1093 @62.4,53.0 mobs=3988
C 1062 @66.2,49.7 mobs=3989
T 1093 @59.0,62.6 id=4201
A 1094 @59.0,62.6 id=4201 lvl=21
C 6301 @49.8,43.4
T 6301 @47.5,58.4 id=11864
A 6381 @47.5,58.4 id=11864 lvl=25
C 6282 @35.8,68.5 mobs=4022,4024,4023,4025
C 6381 @33.6,69.6
C 6393 @31.7,73.3 mobs=4036,4038,4037 danger=1
T 6393 @47.4,64.2 id=11862 danger=1
T 6282 @47.2,61.2 id=11860
T 6381 @47.5,58.4 id=11864
A 6461 @71.2,95.0 id=12816 lvl=19
T 1060 @74.5,97.9 id=3995
A 1058 @74.5,97.9 id=3995 lvl=26
C 6548 @82.2,87.5 mobs=11911,11910
C 6461 @53.8,74.5 mobs=4007,4005
A 5881 @47.2,61.2 id=11860 lvl=28
C 1058 @35.6,18.4 mobs=4018,4020,4067,4019,4016
C 1087 @36.3,13.0 mobs=4057,4053,4051
T 1087 @45.9,60.4 id=4198
T 6461 @71.2,95.0 id=12816
T 1058 @74.5,97.9 id=3995
L 26 "Tue des monstres autour de toi jusqu'au niveau 26"
]],
})

ns.RegisterGuide({
    id = "horde-orc-26-ashenvale",
    name = "Orneval 26-27",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 26, maxLevel = 27,
    next = "horde-orc-26-barrens-3",
    text = [[
M ashenvale
G "Rejoins Orneval" @11.9,34.5 r=40 upto=28
T 6562 @11.6,34.3 id=12736
A 216 @11.9,34.5 id=12757 lvl=24
A 6442 @11.7,34.9 id=12719 lvl=19
A 6462 @11.7,34.9 id=12721 lvl=24
A 6563 @11.6,34.3 id=12736 lvl=22
C 6442 @7.1,14.0 mobs=3717,3944,3711,3712,3715
C 6563 @13.5,12.3
T 6442 @11.7,34.9 id=12719
T 6563 @11.6,34.3 id=12736
C 216 @37.0,35.0 mobs=3924,3925
C 6462 @40.7,33.6
T 216 @11.9,34.5 id=12757
T 6462 @11.7,34.9 id=12721
A 6503 @71.1,68.1 id=12867 lvl=24
C 6503 @74.5,70.4 mobs=12856
T 6503 @71.1,68.1 id=12867
T 6382 @73.8,61.5 id=12696
A 6383 @73.8,61.5 id=12696 lvl=20
A 6441 @73.1,61.5 id=12724 lvl=26 danger=1
T 6383 @73.8,61.5 id=12696
C 6441 @81.1,49.8 mobs=3770,3755,3763,3771,3762 danger=1
T 6441 @73.1,61.5 id=12724 danger=1
]],
})

ns.RegisterGuide({
    id = "horde-orc-26-barrens-3",
    name = "Les Tarides 26-30",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 26, maxLevel = 30,
    next = "horde-orc-30-hillsbrad",
    text = [[
M barrens
H "Utilise ta pierre de foyer" @52.0,29.9 id=3934
T 1069 @62.4,37.6 id=3446
T 1094 @63.0,37.2 id=3442
T 1062 @35.3,27.9 id=4049
T 6548 @35.2,27.8 id=11857
L 27 "Tue des monstres autour de toi jusqu'au niveau 27"
A 857 @49.0,86.3 id=3421 lvl=30
C 857 @49.1,84.2
T 857 @49.0,86.3 id=3421
L 30 "Tue des monstres autour de toi jusqu'au niveau 30"
A 1362 @45.3,28.4 id=3389 lvl=32
]],
})

ns.RegisterGuide({
    id = "horde-orc-30-hillsbrad",
    name = "Contreforts de Hautebrande 30-32",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 30, maxLevel = 32,
    next = "horde-orc-32-needles",
    text = [[
M hillsbrad
G "Rejoins Contreforts de Hautebrande" @61.4,19.1 r=40 upto=34
T 493 @61.4,19.1 id=2216
A 496 @61.4,19.1 id=2216 lvl=22
A 498 @63.2,20.7 id=2229 lvl=22
A 501 @61.4,19.1 id=2216 lvl=24 danger=1
A 509 @61.4,19.1 id=2216 lvl=28
A 527 @62.3,20.4 id=2215 lvl=24
A 549 @62.6,20.8 lvl=22
A 552 @63.9,19.7 id=2429 lvl=33 danger=1
A 567 @62.6,19.7 lvl=28
A 676 @61.9,19.6 id=2770 lvl=32
C 501 @53.4,40.4 mobs=2384,2406,2407,2385 danger=1
C 552 @44.4,29.9 mobs=2251,2250,2248,2249 danger=1
C 527 @32.7,37.9 mobs=2266,2360,232,2403
C 567 @31.1,41.1 mobs=2448,2449,2450,2451
C 496 @38.9,58.0 mobs=2349,2356,2351,2354,2350
C 509 @64.4,61.3
C 498 @75.3,41.5
C 549 @79.9,43.3 mobs=2261,2260
T 496 @61.4,19.1 id=2216
T 498 @63.2,20.7 id=2229
T 501 @61.4,19.1 id=2216 danger=1
T 509 @61.4,19.1 id=2216
T 527 @62.3,20.4 id=2215
T 549 @62.3,20.4 id=2215
T 552 @63.9,19.7 id=2429 danger=1
T 567 @62.3,20.4 id=2215
A 499 @61.4,19.1 id=2216 lvl=22
A 502 @61.4,19.1 id=2216 lvl=24
A 528 @62.3,20.4 id=2215 lvl=25
A 546 @62.1,19.7 id=2418 lvl=25
T 499 @61.5,19.1 id=2230
T 502 @32.7,35.3 id=2274
C 546 @32.3,39.7 mobs=2261,2269,2244,2266,2360
C 528 @34.6,45.6 mobs=2267
T 528 @62.3,20.4 id=2215
T 546 @62.1,19.7 id=2418
A 529 @62.3,20.4 id=2215 lvl=26
C 529 @31.8,45.3 mobs=2265,2404
T 529 @62.3,20.4 id=2215
A 532 @62.3,20.4 id=2215 lvl=26
C 532 @30.2,42.3 mobs=2387,2335
T 532 @62.3,20.4 id=2215
A 539 @62.3,20.4 id=2215 lvl=28
C 539 @29.9,55.6 mobs=2269,2305
T 539 @62.3,20.4 id=2215
L 32 "Tue des monstres autour de toi jusqu'au niveau 32"
]],
})

ns.RegisterGuide({
    id = "horde-orc-32-needles",
    name = "Mille pointes 32-34",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 32, maxLevel = 34,
    next = "horde-orc-34-stv",
    text = [[
M needles
G "Rejoins Mille pointes" @80.2,75.9 r=40 upto=36
A 1105 @78.1,77.1 id=4453 lvl=30 danger=1
A 1175 @81.6,78.0 id=4629 lvl=33 danger=1
A 1176 @80.2,75.9 id=4630 lvl=30
A 1104 @78.1,77.1 id=4454 lvl=30
A 1106 @78.1,77.1 id=4454 lvl=35
A 1110 @77.8,77.3 id=4452 lvl=31
A 5762 @77.8,77.3 id=4452 lvl=31
C 1175 @78.1,88.2 mobs=4151,4147,4150 danger=1
T 1175 @81.6,78.0 id=4629 danger=1
C 1176 @87.9,65.4 mobs=4154,4158
C 1105 @81.8,54.2 mobs=4143,4142,4144 danger=1
C 1104 @76.7,54.6 mobs=4140,4139
C 1110 @70.7,58.7
T 1105 @78.1,77.1 id=4453 danger=1
T 1104 @78.1,77.1 id=4454
T 1110 @77.8,77.3 id=4452
T 1176 @80.2,75.9 id=4630
A 4767 @44.9,48.9 id=10377 lvl=29
A 4821 @44.6,50.3 id=10539 lvl=26
A 5147 @46.0,50.9 lvl=29
A 5361 @45.7,50.7 id=10537 lvl=35
C 4821 @56.4,50.4
T 4821 @44.6,50.3 id=10539
A 4865 @44.6,50.3 id=10539 lvl=26
C 5147 @38.1,26.9 mobs=10896
T 5881 @31.9,21.7 id=12576
A 4542 @32.2,22.2 id=10079 lvl=25
T 4865 @21.5,32.4 id=10428
C 4767 @11.6,35.5
T 4767 @44.9,48.9 id=10377
T 5147 @45.7,50.7 id=10537
T 4542 @45.7,50.7 id=10537
A 4841 @45.7,50.7 id=10537 lvl=25
C 4841 @43.0,38.6 mobs=4096,4093,4094
T 4841 @45.7,50.7 id=10537
A 5064 @45.7,50.7 id=10537 lvl=28
C 5064 @33.8,40.0
T 5064 @45.7,50.7 id=10537
L 34 "Tue des monstres autour de toi jusqu'au niveau 34"
]],
})

ns.RegisterGuide({
    id = "horde-orc-34-stv",
    name = "Vallée de Strangleronce 34-37",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 34, maxLevel = 37,
    next = "horde-orc-37-arathi",
    text = [[
M stv
G "Rejoins Vallée de Strangleronce" @32.2,28.9 r=40 upto=39
A 568 @32.2,28.9 id=2464 lvl=36
A 581 @32.2,27.7 id=2497 lvl=34 danger=1
A 596 @32.3,27.7 id=2519 lvl=37 danger=1
A 629 @32.3,27.7 id=2519 lvl=37
A 638 @32.2,27.7 id=2497 lvl=37
C 568 @31.7,23.5 mobs=686
T 568 @32.2,28.9 id=2464
A 569 @32.2,28.9 id=2464 lvl=37 danger=1
C 569 @37.1,30.8 mobs=1142,1144 danger=1
T 569 @32.2,28.9 id=2464 danger=1
C 629 @24.8,23.0
T 629 @32.3,27.7 id=2519
T 5762 @35.7,10.8 id=715
A 583 @35.7,10.5 id=716 lvl=30
T 583 @35.7,10.8 id=715
A 185 @35.6,10.6 id=717 lvl=31
A 190 @35.5,10.6 id=718 lvl=31
A 194 @35.7,10.8 id=715 lvl=34
C 185 @34.2,11.7 mobs=681
T 185 @35.6,10.6 id=717
A 186 @35.6,10.6 id=717 lvl=33
C 190 @41.9,12.2 mobs=683
C 186 @46.7,15.1 mobs=682
T 190 @35.5,10.6 id=718
T 186 @35.6,10.6 id=717
A 187 @35.6,10.6 id=717 lvl=35
A 191 @35.5,10.6 id=718 lvl=33
C 187 @32.5,18.3 mobs=1085
C 191 @28.8,14.6 mobs=736
C 194 @25.6,16.2 mobs=685
C 581 @24.8,10.9 mobs=701,588,671,597,595 danger=1
C 596 @24.8,10.9 mobs=701,588,671,597,595 danger=1
T 194 @35.7,10.8 id=715
T 187 @35.6,10.6 id=717
T 191 @35.5,10.6 id=718
A 188 @35.6,10.6 id=717 lvl=37
A 192 @35.5,10.6 id=718 lvl=38 danger=1
A 195 @35.7,10.8 id=715 lvl=36
C 188 @32.2,17.4 mobs=729
C 195 @31.7,23.5 mobs=686
T 581 @32.2,27.7 id=2497 danger=1
T 596 @32.3,27.7 id=2519 danger=1
A 570 @32.1,29.2 id=2465 lvl=38 danger=1
A 582 @32.2,27.7 id=2497 lvl=37
T 188 @35.6,10.6 id=717
T 195 @35.7,10.8 id=715
C 582 @23.3,9.9 mobs=671
T 582 @32.2,27.7 id=2497
C 192 @49.2,22.7 mobs=684 danger=1
C 570 @49.2,22.7 mobs=684,772,1713 danger=1
T 192 @35.5,10.6 id=718 danger=1
T 570 @32.1,29.2 id=2465 danger=1
A 189 @27.0,77.1 id=737 lvl=35
A 213 @27.0,77.1 id=737 lvl=36
A 575 @28.3,77.6 id=2495 lvl=31
A 605 @27.1,77.2 id=2498 lvl=35 danger=1
C 605 @43.1,47.8 mobs=1551,690,689,1550,688 danger=1
C 213 @44.0,19.0 mobs=1096
C 575 @40.2,12.9 mobs=1150
C 189 @24.8,10.9 mobs=701,588,671,597,595
T 189 @27.0,77.1 id=737
T 213 @27.0,77.1 id=737
T 575 @28.3,77.6 id=2495
T 605 @27.1,77.2 id=2498 danger=1
A 577 @28.3,77.6 id=2495 lvl=36
C 577 @41.1,17.2 mobs=1152
T 577 @28.3,77.6 id=2495
L 37 "Tue des monstres autour de toi jusqu'au niveau 37"
A 339 @35.7,10.5 id=716 lvl=40 danger=1
A 340 @35.7,10.5 id=716 lvl=40 danger=1
A 341 @35.7,10.5 id=716 lvl=40 danger=1
A 342 @35.7,10.5 id=716 lvl=40 danger=1
C 339 @24.2,10.3 mobs=667,696,780,1096,701 danger=1
C 342 @23.8,10.5 mobs=667,696,780,1096,701 danger=1
T 339 @35.7,10.5 id=716 danger=1
T 342 @35.7,10.5 id=716 danger=1
C 340 @46.7,40.1 mobs=667,696,780,1096,701 danger=1
C 341 @46.2,40.0 mobs=667,696,780,1096,701 danger=1
T 340 @35.7,10.5 id=716 danger=1
T 341 @35.7,10.5 id=716 danger=1
]],
})

ns.RegisterGuide({
    id = "horde-orc-37-arathi",
    name = "Hautes-terres d'Arathi 37-39",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 37, maxLevel = 39,
    next = "horde-orc-39-desolace",
    text = [[
M arathi
G "Rejoins Hautes-terres d'Arathi" @72.6,33.9 r=40 upto=41
T 638 @73.8,34.0 id=2703
A 655 @72.6,33.9 id=2792 lvl=34
A 671 @74.7,36.3 id=2706 lvl=33
T 655 @74.7,36.3 id=2706
A 672 @74.7,36.3 id=2706 lvl=34
C 672 @66.6,39.2 mobs=2559,2560
A 642 @62.5,33.7 lvl=37
T 672 @74.7,36.3 id=2706
A 674 @74.7,36.3 id=2706 lvl=34
T 674 @72.6,33.9 id=2792
A 675 @72.6,33.9 id=2792 lvl=34
T 675 @74.7,36.3 id=2706
A 701 @74.7,36.3 id=2706 lvl=37
C 642 @84.2,32.9 mobs=2572,2574,2573
T 642 @84.3,30.9
A 651 @84.3,30.9 lvl=38
C 701 @52.0,67.4 mobs=2561
A 663 @31.8,82.7 id=2766 lvl=35
A 664 @34.0,80.8 id=2769 lvl=40 danger=1
T 663 @32.3,81.4 id=2610
A 662 @32.8,81.5 id=2767 lvl=40
C 664 @21.9,86.6 mobs=2595,2596 danger=1
C 662 @21.9,85.1
T 664 @34.0,80.8 id=2769 danger=1
T 662 @32.8,81.5 id=2767
C 676 @33.6,44.7 mobs=2562,2564
C 671 @32.2,28.6 mobs=2586,2589,2587
C 651 @25.6,30.4 mobs=2760
T 651 @36.2,57.4
T 676 @74.2,33.9 id=2771
T 671 @74.7,36.3 id=2706
T 701 @74.7,36.3 id=2706
A 677 @74.2,33.9 id=2771 lvl=32
A 702 @74.7,36.3 id=2706 lvl=37
T 702 @72.6,33.9 id=2792
A 847 @72.6,33.9 id=2792 lvl=37
T 847 @74.7,36.3 id=2706
C 677 @68.5,79.5 mobs=2556,2554,2555
T 677 @74.2,33.9 id=2771
A 678 @74.2,33.9 id=2771 lvl=38
C 678 @53.1,76.6 mobs=2566,2567
T 678 @74.2,33.9 id=2771
L 39 "Tue des monstres autour de toi jusqu'au niveau 39"
]],
})

ns.RegisterGuide({
    id = "horde-orc-39-desolace",
    name = "Désolace 39-41",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 39, maxLevel = 41,
    next = "horde-orc-41-dustwallow",
    text = [[
M desolace
G "Rejoins Désolace" @55.4,55.8 r=40 upto=43
T 5361 @55.4,55.8 id=11259
T 1362 @56.2,59.6 id=5395
A 1365 @56.2,59.6 id=5395 lvl=35
A 1367 @56.3,59.7 id=5412 lvl=33
A 1368 @56.3,59.7 id=5412 lvl=33
A 1434 @52.6,54.4 id=5641 lvl=33
A 5501 @62.3,39.0 id=11438 lvl=39
C 1365 @73.4,41.6 mobs=5600
C 1434 @73.7,18.9 mobs=4675,4672,4673,4670
T 1434 @52.6,54.4 id=5641
C 5501 @52.8,59.1
T 1365 @56.2,59.6 id=5395
A 1366 @56.2,59.6 id=5395 lvl=31
T 5501 @62.3,39.0 id=11438
T 1367 @75.0,68.2 id=5398
A 1369 @75.0,68.2 id=5398 lvl=33
T 1368 @36.2,79.2 id=5397
A 1370 @36.2,79.2 id=5397 lvl=35
C 1366 @39.3,94.2 mobs=4649,4648,4640,4641,4655
C 1369 @39.7,93.7
A 5763 @25.1,72.3 id=11877 lvl=31
A 6143 @23.3,72.9 id=12340 lvl=36
A 6142 @22.6,72.0 id=12031 lvl=35
A 6161 @36.1,30.4 lvl=36
A 5741 @38.9,27.2 id=11863 lvl=33
C 6143 @36.3,23.4 mobs=4714,4711,4712
C 6142 @35.0,25.1 mobs=11562,4714,11563,4711,12347
C 6161 @29.0,9.3 mobs=11562,4714,11563,4711,4719
T 6161 @30.0,8.7
C 5741 @55.2,30.1 mobs=13019
T 5741 @38.9,27.2 id=11863
T 1366 @56.2,59.6 id=5395
T 1369 @75.0,68.2 id=5398
C 1370 @73.0,74.7
T 1370 @36.2,79.2 id=5397
T 6143 @23.3,72.9 id=12340
T 6142 @22.6,72.0 id=12031
L 41 "Tue des monstres autour de toi jusqu'au niveau 41"
]],
})

ns.RegisterGuide({
    id = "horde-orc-41-dustwallow",
    name = "Marécage d'Âprefange 41-42",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 41, maxLevel = 42,
    next = "horde-orc-41-badlands",
    text = [[
M dustwallow
G "Rejoins Marécage d'Âprefange" @36.3,31.4 r=40 upto=43
A 1166 @36.3,31.4 id=4500 lvl=43
A 1168 @37.4,31.4 id=4502 lvl=43 danger=1
A 1169 @37.1,33.1 id=4501 lvl=43
A 1201 @35.2,30.7 id=4791 lvl=35
A 1177 @35.1,38.3 id=4503 lvl=36
A 1251 @29.6,48.6 lvl=35
A 1268 @29.7,47.6 lvl=35
A 1269 @29.8,48.2 lvl=37
T 1251 @36.4,31.9 id=4926
T 1268 @36.4,31.9 id=4926
T 1269 @36.4,31.9 id=4926
A 1321 @36.4,31.9 id=4926 lvl=35
T 1321 @36.5,30.8 id=5087
A 1322 @36.5,30.8 id=5087 lvl=37
C 1201 @39.4,24.3 mobs=4834
T 1201 @35.2,30.7 id=4791
A 1202 @35.2,30.7 id=4791 lvl=35
C 1322 @32.0,21.9 mobs=4412,4415,4414,4379,4376
T 1322 @36.5,30.8 id=5087
A 1323 @36.5,30.8 id=5087 lvl=37
T 1323 @36.4,31.9 id=4926
A 1218 @55.4,26.3 id=4792 lvl=35
A 1238 @55.4,25.9 lvl=35
T 1218 @55.4,26.3 id=4792
A 1206 @55.4,26.3 id=4792 lvl=35
C 1177 @57.5,15.8 mobs=4359,4361,4362,4363,14230
T 1238 @35.2,30.7 id=4791
T 1177 @35.1,38.3 id=4503
C 1206 @32.0,21.9 mobs=4379,4376,4378,4380
T 1206 @55.4,26.3 id=4792
A 1239 @55.4,25.9 lvl=35
T 1239 @35.2,30.7 id=4791
A 1240 @35.2,30.7 id=4791 lvl=35
C 1166 @44.5,66.0
C 1168 @44.0,66.2 mobs=4331,4329,4328 danger=1
C 1169 @46.8,67.2 mobs=4323,4324
T 1166 @36.3,31.4 id=4500
T 1168 @37.4,31.4 id=4502 danger=1
T 1169 @37.1,33.1 id=4501
A 1170 @37.1,33.1 id=4501 lvl=43
T 1170 @36.3,31.4 id=4500
A 1171 @36.3,31.4 id=4500 lvl=43
T 1171 @37.1,33.1 id=4501
C 1202 @71.5,51.2
T 1202 @35.2,30.7 id=4791
]],
})

ns.RegisterGuide({
    id = "horde-orc-41-badlands",
    name = "Terres ingrates 41-44",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 41, maxLevel = 44,
    next = "horde-orc-44-swamp",
    text = [[
M badlands
G "Rejoins Terres ingrates" @2.9,45.6 r=40 upto=46
A 782 @2.9,45.6 id=1068 lvl=43
A 1419 @6.5,47.2 id=5394 lvl=40
A 1420 @6.5,47.2 id=5394 lvl=40
A 2258 @2.4,46.1 id=6868 lvl=39 danger=1
A 710 @25.9,44.9 id=2921 lvl=37
C 710 @20.4,44.6 mobs=2735
T 710 @25.9,44.9 id=2921
A 711 @25.9,44.9 id=2921 lvl=39
T 1106 @42.2,52.7 id=4618
A 703 @42.4,52.9 id=2817 lvl=40 danger=1
A 705 @42.4,52.9 id=2817 lvl=37
A 1108 @42.2,52.7 id=4618 lvl=39
C 1108 @50.2,68.3 mobs=2893,2894
C 1419 @55.8,56.7 mobs=2729,2728,2727,2730
C 2258 @58.8,54.5 mobs=2729,2728,92,2727,2736 danger=1
T 1108 @42.2,52.7 id=4618
C 705 @41.5,29.8 mobs=2744
T 705 @42.4,52.9 id=2817
C 711 @42.9,81.7 mobs=92
T 711 @25.9,44.9 id=2921
A 712 @25.9,44.9 id=2921 lvl=42
C 703 @16.2,60.1 mobs=4692,4693,5429,5428,2578 danger=1
C 782 @12.6,75.5 mobs=2944
C 712 @4.0,79.9 mobs=2736
T 782 @2.9,45.6 id=1068
T 1419 @6.5,47.2 id=5394
T 2258 @2.4,46.1 id=6868 danger=1
A 2202 @2.4,46.1 id=6868 lvl=42
T 712 @25.9,44.9 id=2921
C 2202 @34.0,24.4
T 703 @42.4,52.9 id=2817 danger=1
T 2202 @2.4,46.1 id=6868
L 44 "Tue des monstres autour de toi jusqu'au niveau 44"
]],
})

ns.RegisterGuide({
    id = "horde-orc-44-swamp",
    name = "Marais des Chagrins 44-45",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 44, maxLevel = 45,
    next = "horde-orc-44-stv-2",
    text = [[
M swamp
G "Rejoins Marais des Chagrins" @44.7,57.2 r=40 upto=46
T 1420 @47.7,55.2 id=1442
A 698 @44.7,57.2 id=5591 lvl=40
A 1424 @47.9,54.8 id=1443 lvl=43
A 1430 @44.7,57.2 id=5591 lvl=44
C 698 @55.2,51.1 mobs=1087,1082
C 1424 @70.5,50.4
T 1424 @47.9,54.8 id=1443
A 1429 @47.9,54.8 id=1443 lvl=44
T 698 @81.3,81.0 id=5592
A 699 @81.3,81.0 id=5592 lvl=42
C 1430 @93.9,62.8 mobs=1088
C 699 @81.9,30.3 mobs=1087
T 699 @81.3,81.0 id=5592
A 1422 @81.3,81.0 id=5592 lvl=45
T 1422 @83.8,80.4 id=5593
A 1426 @83.8,80.4 id=5593 lvl=43
C 1426 @84.3,88.6 mobs=750,751,747
T 1426 @83.8,80.4 id=5593
A 1427 @83.8,80.4 id=5593 lvl=43
T 1427 @81.3,81.0 id=5592
A 1428 @83.8,80.4 id=5593 lvl=45
C 1428 @63.2,84.8 mobs=750,751,752
T 1428 @83.8,80.4 id=5593
T 1430 @44.7,57.2 id=5591
]],
})

ns.RegisterGuide({
    id = "horde-orc-44-stv-2",
    name = "Vallée de Strangleronce 44-47",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 44, maxLevel = 47,
    next = "horde-orc-47-tanaris",
    text = [[
M stv
G "Rejoins Vallée de Strangleronce" @27.0,77.1 r=40 upto=49
A 209 @27.0,77.1 id=737 lvl=42
A 595 @28.1,76.2 id=2490 lvl=41
A 600 @27.1,77.2 id=2498 lvl=41
A 606 @27.8,77.1 id=2501 lvl=41
A 617 @26.8,76.4 id=2494 lvl=43
A 621 @27.1,77.2 id=2498 lvl=44
A 2864 @26.9,77.2 id=773 lvl=45
A 2872 @27.8,77.1 id=2501 lvl=45
T 595 @27.3,69.5
A 597 @27.3,69.5 lvl=41
T 597 @28.1,76.2 id=2490
A 576 @28.6,75.9 id=2493 lvl=42
A 599 @28.1,76.2 id=2490 lvl=41
T 599 @27.2,77.0 id=2487
A 587 @26.9,77.3 id=2488 lvl=41
A 604 @27.2,77.0 id=2487 lvl=43
C 604 @27.4,82.8 mobs=1563
T 604 @27.2,77.0 id=2487
A 608 @27.2,77.0 id=2487 lvl=45 danger=1
C 576 @30.0,89.3 mobs=1565,1653,1564,1563,4505
C 587 @30.0,89.3 mobs=1565,1653,1564,1563,4505
C 608 @32.9,88.2 mobs=2550,2548,2546 danger=1
T 576 @28.6,75.9 id=2493
T 587 @26.9,77.3 id=2488
T 608 @27.2,77.0 id=2487 danger=1
C 606 @33.2,66.0 mobs=1557
C 617 @27.1,62.2 mobs=1907
T 606 @26.9,73.6 id=2502
A 607 @26.9,73.6 id=2502 lvl=41
T 617 @26.8,76.4 id=2494
T 607 @27.8,77.1 id=2501
A 609 @27.8,77.1 id=2501 lvl=44
C 621 @39.7,58.3 mobs=1491,1488,1490,1489,2534
C 609 @35.1,51.6 mobs=2535,2536,2537
C 600 @41.7,43.7 mobs=674,14492,677,676,675
C 209 @46.4,40.1 mobs=667,696,780,783,669
T 1240 @32.3,27.7 id=2519
A 572 @32.1,29.2 id=2465 lvl=41
A 584 @32.2,27.7 id=2497 lvl=41
A 598 @32.3,27.7 id=2519 lvl=42
C 572 @31.1,42.7 mobs=687
T 572 @32.1,29.2 id=2465
A 571 @32.1,29.2 id=2465 lvl=41
T 5763 @35.7,10.8 id=715
A 196 @35.7,10.8 id=715 lvl=41
C 584 @23.5,8.8 mobs=1061,1062
T 584 @32.2,27.6
A 585 @32.2,27.6 lvl=40
A 586 @32.2,27.6 lvl=46
C 196 @31.1,42.7 mobs=687
C 598 @46.4,40.1 mobs=667,696,780,783,669
C 586 @46.8,43.5 mobs=783,669,781,1059
C 585 @46.1,32.3
T 598 @32.3,27.7 id=2519
T 585 @32.2,27.6
T 586 @32.2,27.6
A 588 @32.2,27.6 lvl=45
T 588 @32.3,27.7 id=2519
A 589 @32.3,27.7 id=2519 lvl=45
T 196 @35.7,10.8 id=715
C 589 @43.1,47.8 mobs=1551
C 571 @33.2,66.0 mobs=1557
T 209 @27.0,77.1 id=737
T 600 @27.1,77.2 id=2498
T 621 @27.1,77.2 id=2498
T 609 @27.8,77.1 id=2501
T 571 @32.1,29.2 id=2465
T 589 @32.3,27.7 id=2519
A 573 @32.1,29.2 id=2465 lvl=44
C 573 @27.1,62.2 mobs=1907
T 573 @32.1,29.2 id=2465
L 47 "Tue des monstres autour de toi jusqu'au niveau 47"
]],
})

ns.RegisterGuide({
    id = "horde-orc-47-tanaris",
    name = "Tanaris 47-49",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 47, maxLevel = 49,
    next = "horde-orc-49-feralas",
    text = [[
M tanaris
G "Rejoins Tanaris" @52.5,28.5 r=40 upto=51
A 1690 @52.5,28.5 id=7407 lvl=43
A 1707 @52.5,28.4 id=7408 lvl=44
A 2605 @51.8,28.7 id=7564 lvl=49
A 2781 @51.8,27.0 lvl=46
A 5863 @52.8,27.4 id=11758 lvl=49
T 2864 @51.6,26.8 id=7876
A 3362 @51.6,26.8 id=7876 lvl=50 danger=1
A 3161 @52.7,45.9 id=7771 lvl=48
C 2781 @61.8,38.2 mobs=7847
C 1690 @63.5,31.3 mobs=5616,5618
C 1707 @63.5,31.3 mobs=5616,5617,5615,5618,5623
T 2872 @67.1,24.0 id=7881
A 2873 @67.1,24.0 id=7881 lvl=45
A 2875 @66.8,22.3 lvl=45
A 8365 @66.6,22.3 id=15165 lvl=45
A 8366 @67.1,23.9 id=7882 lvl=45
T 1690 @52.5,28.5 id=7407
T 1707 @52.5,28.4 id=7408
T 2781 @52.5,28.5 id=7407
A 1691 @52.5,28.5 id=7407 lvl=44
C 1691 @59.8,37.8 mobs=5617,5615,5623
T 1691 @52.5,28.5 id=7407
C 5863 @40.8,52.5 mobs=5474,5472,12046
C 3161 @47.1,65.2
T 3161 @52.7,45.9 id=7771
T 5863 @52.8,27.4 id=11758
C 2873 @72.2,46.8
C 2875 @73.4,47.1 mobs=7883
C 8365 @73.5,47.2 mobs=7858,7857,7856,7855,7883
C 8366 @73.5,47.2 mobs=7858,7857,7856,7855
T 2873 @67.1,24.0 id=7881
T 2875 @67.1,23.9 id=7882
T 8365 @66.6,22.3 id=15165
T 8366 @67.1,23.9 id=7882
C 2605 @29.7,66.0 mobs=5481
C 3362 @29.6,66.0 mobs=5485,5490 danger=1
T 2605 @51.8,28.7 id=7564
T 3362 @51.6,26.8 id=7876 danger=1
A 2606 @51.8,28.7 id=7564 lvl=49
T 2606 @51.1,26.9 id=7583
L 49 "Tue des monstres autour de toi jusqu'au niveau 49"
]],
})

ns.RegisterGuide({
    id = "horde-orc-49-feralas",
    name = "Féralas 49-50",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 49, maxLevel = 50,
    next = "horde-orc-49-hinterlands",
    text = [[
M feralas
G "Rejoins Féralas" @74.4,42.9 r=40 upto=51
A 2822 @74.4,42.9 id=7854 lvl=46
A 2862 @74.9,42.5 id=7875 lvl=42
A 3128 @74.4,43.4 id=8115 lvl=50
A 2973 @75.9,42.7 id=4544 lvl=45
A 2975 @75.8,43.6 id=7777 lvl=43
A 3063 @76.2,43.8 id=7776 lvl=50
C 2973 @67.4,47.5 mobs=5278,7997
C 2862 @70.4,54.6 mobs=5254,5255,5251,5249,5253
T 2862 @74.9,42.5 id=7875
T 2973 @75.9,42.7 id=4544
A 2863 @74.9,42.5 id=7875 lvl=43
A 2974 @75.9,42.7 id=4544 lvl=45
C 2974 @67.0,46.9 mobs=7725,7726,7727
C 2863 @65.6,52.5 mobs=5258
T 2863 @74.9,42.5 id=7875
T 2974 @75.9,42.7 id=4544
A 2902 @74.9,42.5 id=7875 lvl=43
T 2902 @71.6,55.9
A 2903 @71.6,55.9 lvl=43
T 2903 @74.9,42.5 id=7875
A 7730 @74.9,42.5 id=7875 lvl=45
A 7731 @74.9,42.5 id=7875 lvl=47
C 2975 @75.0,27.4 mobs=5232,5229,5237
T 2975 @75.8,43.6 id=7777
A 2980 @75.8,43.6 id=7777 lvl=44
C 7731 @77.0,61.6 mobs=14661
C 7730 @73.7,63.1 mobs=5247,5244,5245,5246,14661
T 7730 @74.9,42.5 id=7875
T 7731 @74.9,42.5 id=7875
C 2980 @60.9,56.2 mobs=5236,5240,5234
C 2822 @51.8,58.9 mobs=5292,5293,5295,5346
C 3128 @55.0,72.0 mobs=2928,2927,5305,5304,5300
A 7721 @44.8,43.4 id=14637 lvl=48
C 7721 @47.7,52.3 mobs=5462,5461
T 7721 @44.8,43.4 id=14637
C 3063 @39.2,13.2 mobs=5366,5362,5364,5363
T 2822 @74.4,42.9 id=7854
T 3128 @74.4,43.4 id=8115
A 7734 @74.4,42.9 id=7854 lvl=48
T 3063 @76.2,43.8 id=7776
T 2980 @75.8,43.6 id=7777
C 7734 @53.8,32.1 mobs=5299,5296,5297
T 7734 @74.4,42.9 id=7854
]],
})

ns.RegisterGuide({
    id = "horde-orc-49-hinterlands",
    name = "Les Hinterlands 49-50",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 49, maxLevel = 50,
    next = "horde-orc-50-searing",
    text = [[
M hinterlands
G "Rejoins Les Hinterlands" @80.3,81.5 r=40 upto=52
A 7815 @80.3,81.5 id=14740 lvl=50
A 7828 @79.2,79.5 id=14741 lvl=48
A 7829 @79.2,79.5 id=14741 lvl=48
A 7830 @79.2,79.5 id=14741 lvl=48
A 7841 @79.4,79.1 id=14738 lvl=48
A 7845 @78.2,81.2 id=14736 lvl=51
A 7849 @79.2,79.5 id=14741 lvl=50
A 7850 @78.2,81.2 id=14736 lvl=50
A 7839 @77.2,80.1 id=14737 lvl=48
A 7844 @78.8,78.2 id=14739 lvl=48
C 7850 @66.3,70.9
T 7845 @59.7,77.8 id=14757
C 7849 @58.6,64.8
C 7830 @63.8,52.0 mobs=2659
C 7839 @71.0,48.7
C 7828 @71.9,56.6 mobs=2926,2925
C 7815 @83.0,55.2 mobs=2505
T 7815 @80.3,81.5 id=14740
T 7828 @79.2,79.5 id=14741
T 7830 @79.2,79.5 id=14741
T 7849 @79.2,79.5 id=14741
T 7850 @78.2,81.2 id=14736
T 7839 @77.2,80.1 id=14737
C 7829 @54.2,48.6 mobs=2929
C 7844 @47.2,66.3 mobs=4466,4467
T 1429 @33.8,75.2 id=5598
C 7841 @31.1,47.8 mobs=2692,2693,2691,2694
T 7829 @79.2,79.5 id=14741
T 7841 @79.4,79.1 id=14738
T 7844 @78.8,78.2 id=14739
A 7842 @79.4,79.1 id=14738 lvl=48
C 7842 @30.8,58.4 mobs=6375,2651,5300,2657,2347
T 7842 @79.4,79.1 id=14738
]],
})

ns.RegisterGuide({
    id = "horde-orc-50-searing",
    name = "Gorge des Vents brûlants 50-53",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 50, maxLevel = 53,
    next = "horde-orc-53-ungoro",
    text = [[
M searing
G "Rejoins Gorge des Vents brûlants" @38.8,28.5 r=40 upto=55
A 7722 @38.8,28.5 id=14624 lvl=50
A 7723 @38.6,27.8 id=14627 lvl=49
A 7724 @38.6,27.8 id=14627 lvl=49
A 7727 @38.6,27.8 id=14627 lvl=49
A 7728 @37.6,26.5 lvl=48
A 7729 @37.6,26.5 lvl=48
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
A 4449 @65.6,62.2 lvl=45
C 4449 @41.3,37.1 mobs=3819,6195,3823,667,696
T 4449 @65.6,62.2
L 53 "Tue des monstres autour de toi jusqu'au niveau 53"
]],
})

ns.RegisterGuide({
    id = "horde-orc-53-ungoro",
    name = "Cratère d'Un'Goro 53-55",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 53, maxLevel = 55,
    next = "horde-orc-55-azshara",
    text = [[
M ungoro
G "Rejoins Cratère d'Un'Goro" @44.0,7.1 r=40 upto=57
A 3881 @44.0,7.1 id=9270 lvl=53
A 3882 @43.5,7.4 id=9272 lvl=51
A 4145 @45.5,8.7 id=9118 lvl=52
A 4492 @43.6,8.5 id=9997 lvl=55
A 4501 @43.5,8.4 lvl=55
A 4243 @46.4,13.4 id=9618 lvl=53
A 4503 @44.2,11.6 id=9998 lvl=51
A 4284 @41.9,2.7 id=9117 lvl=53
T 4243 @67.7,16.8 id=9623
C 4284 @67.2,15.6 mobs=6510,9167,9164,6512,9163
C 4145 @66.8,30.3 mobs=6510,6512,6511,6509
C 3881 @68.5,36.5
T 4492 @51.9,49.9 id=9999
C 4503 @53.1,62.6 mobs=9167,9164,9163,9166,9165
A 3844 @63.0,68.6 lvl=52
T 3844 @63.1,69.1
A 4289 @71.6,76.0 id=9619 lvl=55
A 4290 @71.6,76.0 id=9619 lvl=53
C 4290 @68.7,56.7
T 4290 @71.6,76.0 id=9619
C 3882 @32.2,74.7 mobs=9164,9163,9162
A 974 @30.9,50.4 id=10302 lvl=55
C 4501 @22.8,40.3 mobs=9167,9166
T 4145 @45.5,8.7 id=9118
T 4501 @43.6,8.5 id=9997
T 4503 @44.2,11.6 id=9998
T 3881 @44.0,7.1 id=9270
T 3882 @43.5,7.4 id=9272
T 4284 @41.9,2.7 id=9117
C 4289 @66.8,15.7 mobs=6514,6513,6516
C 974 @54.0,55.2 mobs=10541
T 4289 @71.6,76.0 id=9619
A 4301 @71.6,76.0 id=9619 lvl=55
T 974 @30.9,50.4 id=10302
A 980 @30.9,50.4 id=10302 lvl=55
C 4301 @68.1,12.6 mobs=9622
T 4301 @71.6,76.0 id=9619
L 55 "Tue des monstres autour de toi jusqu'au niveau 55"
]],
})

ns.RegisterGuide({
    id = "horde-orc-55-azshara",
    name = "Azshara 55-56",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 55, maxLevel = 56,
    next = "horde-orc-56-felwood",
    text = [[
M azshara
G "Rejoins Azshara" @11.4,78.2 r=40 upto=58
A 5535 @11.4,78.2 id=11548 lvl=47
A 5536 @11.4,78.2 id=11548 lvl=47
C 5535 @17.1,69.1 mobs=6116,6117
C 5536 @20.1,61.8 mobs=6125,6126,6127
A 3517 @22.6,51.4 id=8587 lvl=52
C 3517 @36.2,53.9
T 3517 @22.6,51.4 id=8587
A 3561 @22.6,51.4 id=8587 lvl=52
T 3561 @29.2,40.2 id=8379
A 3565 @29.2,40.2 id=8379 lvl=52
T 3565 @22.6,51.4 id=8587
T 5535 @11.4,78.2 id=11548
T 5536 @11.4,78.2 id=11548
A 3601 @53.5,21.8 id=8420 lvl=53
C 3601 @58.2,29.6
T 3601 @53.5,21.8 id=8420
A 5534 @53.5,21.8 id=8420 lvl=53
C 5534 @47.1,49.9 mobs=6195,6196,7885,7886
T 5534 @53.5,21.8 id=8420
L 56 "Tue des monstres autour de toi jusqu'au niveau 56"
]],
})

ns.RegisterGuide({
    id = "horde-orc-56-felwood",
    name = "Gangrebois 56-57",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 56, maxLevel = 57,
    next = "horde-orc-57-winterspring",
    text = [[
M felwood
G "Rejoins Gangrebois" @51.2,82.1 r=40 upto=59
A 5155 @51.2,82.1 id=10922 lvl=51
A 5156 @50.9,81.6 id=10921 lvl=54
A 8460 @50.9,85.0 id=11554 lvl=48
A 4102 @46.8,83.1 id=9529 lvl=55
C 8460 @48.3,91.3 mobs=7153,7154,7155
T 8460 @50.9,85.0 id=11554
A 8462 @50.9,85.0 id=11554 lvl=55
C 5155 @37.8,61.1 mobs=7113,7112,7115,7125
A 6162 @34.8,52.7 id=9620 lvl=51
C 5156 @41.8,39.9 mobs=9878,9879
C 4102 @58.2,20.2 mobs=7100,7101
T 8462 @64.8,8.1 id=15395
A 8461 @64.8,8.1 id=15395 lvl=55
C 8461 @62.4,9.2 mobs=7157,7158,7156
T 8461 @64.8,8.1 id=15395
A 8465 @64.8,8.1 id=15395 lvl=55
T 5155 @51.2,82.1 id=10922
T 5156 @50.9,81.6 id=10921
T 4102 @46.8,83.1 id=9529
A 5882 @46.8,83.1 id=9529 lvl=55
C 6162 @48.2,94.3 mobs=9464
T 6162 @34.8,52.7 id=9620
C 5882 @38.8,47.6 mobs=8959,8960,8956,8958,8957
T 5882 @46.8,83.1 id=9529
L 57 "Tue des monstres autour de toi jusqu'au niveau 57"
]],
})

ns.RegisterGuide({
    id = "horde-orc-57-winterspring",
    name = "Berceau-de-l'Hiver 57-59",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 57, maxLevel = 59,
    next = "horde-orc-59-wpl",
    text = [[
M winterspring
G "Rejoins Berceau-de-l'Hiver" @61.9,38.3 r=40 upto=61
A 969 @61.9,38.3 id=10307 lvl=60
A 3783 @60.9,37.6 id=10305 lvl=56
A 5601 @61.3,39.0 id=11629 lvl=55
A 6030 @61.4,39.0 id=10431 lvl=52
A 6603 @60.7,38.2 id=11754 lvl=56
A 6606 @61.1,38.4 id=11755 lvl=60
T 6606 @61.9,38.3 id=10307
C 3783 @66.7,43.2 mobs=7458,7457
T 3783 @60.9,37.6 id=10305
A 977 @60.9,37.6 id=10305 lvl=58
C 977 @70.5,40.0 mobs=7459,7460
T 977 @60.9,37.6 id=10305
C 969 @59.8,67.2
T 969 @61.9,38.3 id=10307
T 980 @31.3,45.2 id=9298
T 6603 @31.3,45.2 id=9298
A 5082 @31.3,45.2 id=9298 lvl=56
T 8465 @27.7,34.5 id=11556
A 8464 @27.7,34.5 id=11556 lvl=58
C 5082 @40.6,43.5 mobs=7442,7440,7441
T 5082 @31.3,45.2 id=9298
C 8464 @67.2,36.0 mobs=7440,7438,7439
T 8464 @27.7,34.5 id=11556
L 59 "Tue des monstres autour de toi jusqu'au niveau 59"
]],
})

ns.RegisterGuide({
    id = "horde-orc-59-wpl",
    name = "Maleterres de l'Ouest 59-60",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 59, maxLevel = 60,
    next = "horde-orc-60-epl",
    text = [[
M wpl
G "Rejoins Maleterres de l'Ouest" @53.7,64.7 r=40 upto=62
A 4984 @53.7,64.7 id=10739 lvl=54
A 5058 @47.8,50.7 lvl=55
T 5058 @47.8,50.7
C 4984 @45.8,45.9 mobs=1817
A 5021 @38.4,54.0 id=10778 lvl=52
T 5021 @38.7,55.2
T 4984 @53.7,64.7 id=10739
A 4985 @53.7,64.7 id=10739 lvl=56
C 4985 @64.5,48.1 mobs=1816
T 4985 @53.7,64.7 id=10739
A 6004 @51.9,28.1 id=11610 lvl=56
C 6004 @51.2,42.7 mobs=1833,1831,10605,1826
T 6004 @51.9,28.1 id=11610
A 6023 @51.9,28.1 id=11610 lvl=57
C 6023 @57.8,36.1 mobs=11613,11611
T 6023 @51.9,28.1 id=11610
L 60 "Tue des monstres autour de toi jusqu'au niveau 60"
]],
})

ns.RegisterGuide({
    id = "horde-orc-60-epl",
    name = "Maleterres de l'Est 60-61",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 60, maxLevel = 61,
    next = "horde-orc-60-silithus",
    text = [[
M epl
G "Rejoins Maleterres de l'Est" @71.6,50.1 r=40 upto=62
T 6030 @71.6,50.1 id=11039
A 5503 @71.6,50.1 id=11039 lvl=55
A 9124 @71.7,48.9 id=16132 lvl=60
A 9126 @71.6,48.9 id=16131 lvl=60
A 9128 @71.7,48.7 id=16116 lvl=60
A 9665 @70.4,47.9 id=17072 lvl=60
T 5503 @71.6,50.1 id=11039
A 5281 @69.9,53.7 id=11038 lvl=60
A 6021 @69.9,53.7 id=11038 lvl=55
C 9126 @58.7,31.1 mobs=1789,1783,1787,1784,8523
T 9126 @71.6,48.9 id=16131
C 9128 @53.6,68.5 mobs=11744,11746,6521,9878,9879
C 9665 @34.1,64.1 mobs=17689,17690,17696,17698
T 5601 @31.1,78.0 id=10926
A 6024 @22.9,73.0 lvl=60
C 6021 @23.1,72.6 mobs=12250
A 6042 @22.2,63.5 id=11878 lvl=58
A 6133 @22.2,63.5 id=11878 lvl=60
C 6042 @42.1,53.4 mobs=8601,8602
T 6042 @22.2,63.5 id=11878
A 5542 @5.2,35.6 id=1855 lvl=56
A 5543 @5.2,35.6 id=1855 lvl=56
A 5544 @5.2,35.6 id=1855 lvl=56
C 9124 @8.4,27.6 mobs=8558,8555,8557,8556
T 5281 @11.4,26.6 id=11140
A 6164 @11.4,26.4 id=12384 lvl=55
C 6164 @14.0,24.2
T 6164 @11.4,26.4 id=12384
C 5543 @13.9,66.6 mobs=8600
T 5543 @5.2,35.6 id=1855
C 5542 @44.4,31.3 mobs=8598,8596,8597
C 6133 @45.6,12.8 mobs=8564,8563,8565
C 5544 @56.3,23.0 mobs=8603,8605
C 6024 @62.0,11.1 mobs=12248
T 9124 @71.7,48.9 id=16132
T 9128 @71.7,48.7 id=16116
T 9665 @70.4,47.9 id=17072
T 6021 @69.9,53.7 id=11038
T 6133 @22.2,63.5 id=11878
T 6024 @23.6,73.8
T 5542 @5.2,35.6 id=1855
T 5544 @5.2,35.6 id=1855
]],
})

ns.RegisterGuide({
    id = "horde-orc-60-silithus",
    name = "Silithus 60-61",
    faction = "Horde", race = { Orc = true, Troll = true }, path = "horde-orc",
    minLevel = 60, maxLevel = 61,
    text = [[
M silithus
G "Rejoins Silithus" @51.6,38.6 r=40 upto=62
A 8277 @51.6,38.6 id=15189 lvl=55
A 8280 @51.1,38.3 id=15191 lvl=55
A 8284 @49.7,37.5 id=15183 lvl=58
A 8800 @50.0,36.4 id=15540 lvl=60
T 8800 @51.2,38.9 id=15176
A 8304 @49.2,34.2 id=15181 lvl=60
A 8318 @48.6,37.8 id=15306 lvl=60
A 8320 @48.6,37.9 id=15270 lvl=60
A 9416 @49.0,36.7 id=17081 lvl=60
C 8318 @39.4,44.5 mobs=11880,11881,11882,15213,15201
T 8318 @48.6,37.8 id=15306
C 8280 @53.4,17.3 mobs=11740
C 8277 @60.7,21.9 mobs=11735,11738
T 8277 @51.6,38.6 id=15189
T 8280 @51.1,38.3 id=15191
A 8278 @51.6,38.6 id=15189 lvl=57
A 8281 @51.1,38.3 id=15191 lvl=57
T 9416 @50.8,69.5 id=17079
A 9422 @50.8,69.5 id=17079 lvl=60
C 9422 @50.9,69.3 mobs=18199
T 9422 @50.8,69.5 id=17079
C 8304 @41.0,89.0 mobs=15221,15222
C 8278 @33.6,75.5 mobs=11736,11737,11739
C 8281 @30.2,42.8 mobs=11741
C 8320 @26.4,34.7 mobs=11881
C 8284 @22.1,10.4 mobs=14455
T 8284 @49.7,37.5 id=15183
T 8304 @49.2,34.2 id=15181
T 8320 @48.6,37.9 id=15270
A 8285 @49.7,37.5 id=15183 lvl=59
A 8321 @48.6,37.9 id=15270 lvl=60
T 8278 @51.6,38.6 id=15189
T 8281 @51.1,38.3 id=15191
A 8282 @51.6,38.5 id=15190 lvl=58
T 8285 @67.2,69.8 id=15194
A 8279 @67.2,69.8 id=15194 lvl=60
C 8282 @44.6,91.4
T 8282 @51.6,38.5 id=15190
C 8279 @26.4,36.6 mobs=15200,11803,11804
T 8279 @67.2,69.8 id=15194
A 8287 @67.2,69.8 id=15194 lvl=60
A 8323 @67.2,69.8 id=15194 lvl=59
T 8287 @49.2,34.2 id=15181
C 8323 @39.4,44.5 mobs=11880,11881,11882,15213,15201
T 8323 @67.2,69.8 id=15194
C 8321 @72.4,15.6 mobs=15202
T 8321 @48.6,37.9 id=15270
]],
})
