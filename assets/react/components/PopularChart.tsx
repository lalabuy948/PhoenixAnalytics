"use client";

import * as React from "react";
import { format } from "date-fns";
import {
  Bar,
  BarChart,
  CartesianGrid,
  LabelList,
  XAxis,
  YAxis,
} from "recharts";

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";

import { DateRange } from "./DateRange";

const chartConfig = {
  visits: {
    label: "Visits",
    color: "hsl(var(--chart-3))",
  },
  label: {
    color: "hsl(var(--foreground))",
  },
} satisfies ChartConfig;

type ChartData = {
  source: string;
  visits: number;
};

export function PopularChart({
  chartData,
  chartTitle,
  dateRange,
}: {
  chartData: ChartData[];
  chartTitle: string;
  dateRange: DateRange;
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{chartTitle}</CardTitle>
        <CardDescription>
          {format(dateRange.from, "dd LLL, y")} -{" "}
          {format(dateRange.to, "dd LLL, y")}
        </CardDescription>
      </CardHeader>
      <CardContent className="flex-1 pb-0">
        <ChartContainer
          config={chartConfig}
          className="mx-auto aspect-square max-h-[250px]"
        >
          <BarChart
            accessibilityLayer
            data={chartData}
            layout="vertical"
            margin={{
              right: 16,
            }}
          >
            <CartesianGrid horizontal={false} />
            <YAxis
              dataKey="source"
              type="category"
              tickLine={false}
              tickMargin={10}
              axisLine={false}
              tickFormatter={(value) => value.slice(0, 3)}
              hide
            />
            <XAxis dataKey="visits" type="number" hide />
            <ChartTooltip
              cursor={false}
              content={
                <ChartTooltipContent className="w-[200px]" indicator="line" />
              }
            />
            <Bar
              dataKey="visits"
              layout="vertical"
              fill="var(--color-visits)"
              radius={4}
            >
              <LabelList
                dataKey="source"
                position="insideLeft"
                fill="var(--color-label)"
                offset={8}
                fontSize={12}
              />
            </Bar>
          </BarChart>
        </ChartContainer>
      </CardContent>
      <CardFooter className="flex-col items-start gap-2 text-sm mt-2">
        <div className="leading-none text-muted-foreground">
          Showing total visits for {chartTitle.toLowerCase()}
        </div>
      </CardFooter>
    </Card>
  );
}
