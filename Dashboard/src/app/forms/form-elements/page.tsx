import React from "react";
import FormElements from "@/components/FormElements";
import { Metadata } from "next";
import DefaultLayout from "@/components/Layouts/DefaultLaout";

export const metadata: Metadata = {
  title:
    "Company Dashboard",
};

const FormElementsPage = () => {
  return (
    <DefaultLayout>
      <FormElements />
    </DefaultLayout>
  );
};

export default FormElementsPage;
