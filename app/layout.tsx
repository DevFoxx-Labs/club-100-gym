import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Club 100 The Gym | Top Rated 4.8★ Health Club in Transport Nagar, Prayagraj",
  description:
    "Club 100 The Gym in Transport Nagar (TP Nagar), Prayagraj. 4.8★ rated gym with 230+ Google reviews featuring HIIT, Aerobics, Crossfit, Personal Training, Weight Training, Nutrition Consulting, and Cycling.",
  keywords: [
    "Club 100 The Gym",
    "Club 100 Gym Prayagraj",
    "Best Gym in Transport Nagar",
    "Gym in TP Nagar Prayagraj",
    "Top Gym near Kalewam Restaurant",
    "Crossfit Prayagraj",
    "Aerobics Prayagraj",
    "Personal Trainer Transport Nagar",
    "Women Friendly Gym Prayagraj",
    "Weight Loss Gym Transport Nagar",
    "Gym near Meera Patti"
  ],
  authors: [{ name: "Club 100 The Gym" }],
  openGraph: {
    title: "Club 100 The Gym — 4.8★ Health Club in Transport Nagar, Prayagraj",
    description:
      "Health club with top-notch equipment, friendly certified trainers, and supportive atmosphere catering to women too. Crossfit, HIIT, Aerobics, Personal Training, and Cycling.",
    url: "https://club-100-the-gym.grexa.site/",
    siteName: "Club 100 The Gym",
    type: "website",
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": ["ExerciseGym", "HealthClub"],
  "@id": "https://club-100-the-gym.grexa.site/#gym",
  "name": "Club 100 The Gym",
  "alternateName": ["Club 100 Gym", "Club 100 TP Nagar"],
  "url": "https://club-100-the-gym.grexa.site/",
  "telephone": "+91-7084306574",
  "priceRange": "₹₹",
  "slogan": "A HEALTHIER YOU STARTS HERE — STRONGER, HAPPIER, YOU",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "1st Floor TP Nagar, beside of Kalewam Restaurant, Meera Patti, Transport Nagar",
    "addressLocality": "Prayagraj",
    "addressRegion": "Uttar Pradesh",
    "postalCode": "211011",
    "addressCountry": "IN"
  },
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ],
      "opens": "05:00",
      "closes": "20:00"
    }
  ],
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "reviewCount": "230",
    "bestRating": "5",
    "worstRating": "1"
  },
  "hasOfferCatalog": {
    "@type": "OfferCatalog",
    "name": "Gym & Health Club Services",
    "itemListElement": [
      "HIIT exercise classes",
      "Aerobics",
      "Crossfit",
      "Personal training",
      "Weight training",
      "Nutrition consulting",
      "Cycling"
    ]
  }
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Caveat:wght@600;700&family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,800&display=swap" rel="stylesheet" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className="bg-[#0b0c10] text-slate-100 antialiased selection:bg-[#b5f63d] selection:text-[#0b0c10]">
        {children}
      </body>
    </html>
  );
}
