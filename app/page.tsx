"use client";

import React, { useState } from "react";
import Navbar from "./components/Navbar";
import Hero from "./components/Hero";
import FeaturesBar from "./components/FeaturesBar";
import About from "./components/About";
import Services from "./components/Services";
import Trainers from "./components/Trainers";
import Membership from "./components/Membership";
import Reviews from "./components/Reviews";
import Testimonials from "./components/Testimonials";
import CtaBanner from "./components/CtaBanner";
import BmiCalculator from "./components/BmiCalculator";
import Faq from "./components/Faq";
import LocationContact from "./components/LocationContact";
import Footer from "./components/Footer";
import BookingModal from "./components/BookingModal";

export default function Home() {
  const [isBookingOpen, setIsBookingOpen] = useState(false);

  const openBooking = () => setIsBookingOpen(true);
  const closeBooking = () => setIsBookingOpen(false);

  return (
    <div className="min-h-screen bg-[#0b0c10] text-slate-100 font-sans selection:bg-[#b5f63d] selection:text-[#0b0c10]">
      <Navbar onOpenBooking={openBooking} />
      <main>
        <Hero onOpenBooking={openBooking} />
        <FeaturesBar />
        <About onOpenBooking={openBooking} />
        <Services onOpenBooking={openBooking} />
        <Trainers onOpenBooking={openBooking} />
        <Membership onOpenBooking={openBooking} />
        <Reviews />
        <Testimonials />
        <CtaBanner onOpenBooking={openBooking} />
        <BmiCalculator onOpenBooking={openBooking} />
        <Faq onOpenBooking={openBooking} />
        <LocationContact onOpenBooking={openBooking} />
      </main>
      <Footer onOpenBooking={openBooking} />
      <BookingModal isOpen={isBookingOpen} onClose={closeBooking} />
    </div>
  );
}
