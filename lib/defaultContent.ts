export const defaultPlans = [
  {
    _id: "plan-1",
    name: "Basic",
    monthlyPrice: "₹899",
    yearlyPrice: "₹699",
    period: "/month",
    popular: false,
    features: [
      "Full Gym Access (Open Till 8 PM)",
      "Top-Notch Clean Equipment",
      "Locker & Restroom Access",
      "Supportive Trainer Guidance"
    ]
  },
  {
    _id: "plan-2",
    name: "Pro (All Access)",
    monthlyPrice: "₹1,299",
    yearlyPrice: "₹999",
    period: "/month",
    popular: true,
    badge: "Most Popular",
    features: [
      "All Gym & Fitness Facilities",
      "HIIT, Aerobics & Crossfit Classes",
      "Indoor Cycling Spin Studio",
      "Online Workout Sessions",
      "Women Friendly Training Batches"
    ]
  },
  {
    _id: "plan-3",
    name: "Elite VIP",
    monthlyPrice: "₹1,999",
    yearlyPrice: "₹1,599",
    period: "/month",
    popular: false,
    features: [
      "Everything in Pro Access",
      "1-on-1 Personal Trainer Session",
      "Customized Nutrition Consulting",
      "Body Recomposition Assessment"
    ]
  }
];

export const defaultServices = [
  {
    _id: "srv-1",
    title: "HIIT Exercise Classes",
    subtitle: "Maximum Metabolic Burn",
    img: "/class_hiit.jpg",
    category: "Cardio & Weight Loss",
    desc: "High-Intensity Interval Training designed to burn calories fast, increase endurance, and elevate your metabolism for hours post-workout."
  },
  {
    _id: "srv-2",
    title: "Aerobics & Fitness",
    subtitle: "Rhythm & Energy",
    img: "/class_yoga.jpg",
    category: "Cardio & Flexibility",
    desc: "Energetic group aerobic routines combining rhythmic cardio movements, core conditioning, and active recovery for all fitness levels."
  },
  {
    _id: "srv-3",
    title: "Crossfit Conditioning",
    subtitle: "Build Explosive Power",
    img: "/class_strength.jpg",
    category: "Functional Fitness",
    desc: "Constantly varied functional movements executed at high intensity. Combine Olympic lifts, kettlebells, and bodyweight agility exercises."
  },
  {
    _id: "srv-4",
    title: "Personal Training",
    subtitle: "1-on-1 Dedicated Coaching",
    img: "/male_trainer_athlete.jpg",
    category: "Customized Coaching",
    desc: "Work directly with our knowledgeable certified trainers for custom program design, strict form correction, and rapid goal achievement."
  },
  {
    _id: "srv-5",
    title: "Weight Training",
    subtitle: "Build Pure Strength",
    img: "/gym_interior_neon.jpg",
    category: "Strength & Hypertrophy",
    desc: "Train on pristine isolation machines, heavy dumbbells, and squat racks to build dense muscle, increase bone density, and sculpt your physique."
  },
  {
    _id: "srv-6",
    title: "Nutrition Consulting",
    subtitle: "Fuel Your Performance",
    img: "/bmi_bg.png",
    category: "Diet & Lifestyle",
    desc: "Personalized macronutrient guidance, meal timing strategies, and body recomposition planning tailored to your exact metabolic needs."
  },
  {
    _id: "srv-7",
    title: "Indoor Cycling / Spin",
    subtitle: "High-Octane Cardio",
    img: "/class_cycling.jpg",
    category: "Endurance & Legs",
    desc: "High-energy spin bike studio sessions simulating mountain climbs, sprint intervals, and high-cadence endurance rides."
  }
];

export const defaultTrainers = [
  {
    _id: "trn-1",
    name: "Vikram Singh",
    category: "Strength & Crossfit",
    specialties: "Crossfit • Powerlifting • Weight Loss",
    description: "Helping you build functional power and physical resilience.",
    fullBio: "Vikram is a certified strength specialist with 8+ years experience guiding athletes and fitness beginners in Prayagraj. He focuses on movement precision, progressive strength building, and injury prevention.",
    experience: "8+ Years",
    certifications: ["Certified Strength & Conditioning Specialist", "Crossfit Level 2 Trainer", "Precision Sports Nutrition"],
    rating: 4.9,
    isTopRated: true,
    image: "/trainer_ava.jpg"
  },
  {
    _id: "trn-2",
    name: "Priya Sharma",
    category: "Aerobics & HIIT",
    specialties: "HIIT • Aerobics • Women's Fitness",
    description: "High energy, encouraging workouts catering to every woman.",
    fullBio: "Priya specializes in high-intensity cardiovascular conditioning, aerobics fusion, and women's fitness transformations. Her sessions build core endurance while maintaining a super positive atmosphere.",
    experience: "6+ Years",
    certifications: ["ACE Group Fitness Instructor", "Aerobics & Cardio Specialist", "Women's Wellness Coach"],
    rating: 4.9,
    isTopRated: false,
    image: "/trainer_lily.jpg"
  },
  {
    _id: "trn-3",
    name: "Rohit Verma",
    category: "Personal Training",
    specialties: "Muscle Building • Recomposition • Weight Training",
    description: "Scientific programming for body transformation.",
    fullBio: "Rohit combines hypertrophy science with tailored nutrition consulting. He has helped over 300+ gym members reach their target body composition with sustainable habits.",
    experience: "7+ Years",
    certifications: ["NASM Master Certified Personal Trainer", "ISSA Sports Nutrition Specialist"],
    rating: 4.8,
    isTopRated: false,
    image: "/trainer_ethan.jpg"
  },
  {
    _id: "trn-4",
    name: "Amit Kumar",
    category: "Spin & Cardio",
    specialties: "Cycling • Stamina • Kickboxing",
    description: "Pushing endurance limits with high-octane cardio.",
    fullBio: "Amit leads high-energy indoor cycling spin rides and kickboxing cardio sessions designed to shred calories and elevate stamina.",
    experience: "9+ Years",
    certifications: ["Indoor Cycling Master Instructor", "Functional Cardio Specialist"],
    rating: 4.9,
    isTopRated: false,
    image: "/trainer_noah.jpg"
  }
];

export const defaultGymInfo = {
  _id: "gym-info-main",
  name: "Club 100 The Gym",
  address: "1st Floor TP Nagar, beside of Kalewam Restaurant, Meera Patti, Transport Nagar, Prayagraj, Uttar Pradesh 211011",
  phone: "070843 06574",
  hours: "Open Daily · Closes 8:00 PM",
  mapsUrl: "https://maps.google.com/?q=1st+Floor+TP+Nagar,+beside+of+Kalewam+Restaurant,+Meera+Patti,+Transport+Nagar,+Prayagraj,+Uttar+Pradesh+211011",
  whatsappUrl: "https://wa.me/917084306574",
  instagramUrl: "https://instagram.com",
  facebookUrl: "https://facebook.com",
  youtubeUrl: "https://youtube.com",
  rating: "4.8",
  reviewCount: "230"
};
