"use client";

import * as React from "react";
import { format } from "date-fns";
import { Bar, BarChart, Rectangle, XAxis } from "recharts";

import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";

import { ChartContainer } from "@/components/ui/chart";
import { nFormatter } from "./lib/utils";

import { DateRange } from "./DateRange";

type ChartData = {
  date: string;
  hits: number;
};

const ChartConfig = {
  hits: {
    label: "Hits",
    color: "hsl(var(--chart-1))",
  },
};

export function SingleStat({
  statData,
  statUnit,
  statTitle,
  chartData,
  dateRange,
}: {
  statData: number;
  statUnit: string;
  statTitle: string;
  chartData: ChartData[];
  dateRange: DateRange;
}) {
  return (
    <Card>
      <CardHeader className="p-4 pb-0">
        <CardTitle>{statTitle}</CardTitle>
        <CardDescription>
          {format(dateRange.from, "dd LLL, y")} -{" "}
          {format(dateRange.to, "dd LLL, y")}
        </CardDescription>
      </CardHeader>
      <CardContent className="flex flex-row items-baseline gap-4 p-4 pt-0">
        <div className="flex items-baseline gap-1 text-xl font-bold tabular-nums leading-none">
          {statUnit === "time"
            ? statData < 60000
              ? `${(statData / 1000).toFixed(2)}s`
              : `${(statData / 60000).toFixed(2)}m`
            : nFormatter(statData, 2)}
          <span className="text-sm font-normal text-muted-foreground">
            {statUnit}/period
          </span>
        </div>
        <ChartContainer config={ChartConfig} className="ml-auto w-[72px]">
          <BarChart
            accessibilityLayer
            margin={{
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
            }}
            data={chartData}
          >
            <Bar
              dataKey="hits"
              fill="var(--color-hits)"
              radius={2}
              fillOpacity={0.2}
              activeIndex={chartData.length - 1}
              activeBar={<Rectangle fillOpacity={0.8} />}
            />
            <XAxis
              dataKey="date"
              tickLine={false}
              axisLine={false}
              tickMargin={4}
              hide
            />
          </BarChart>
        </ChartContainer>
      </CardContent>
    </Card>
  );
}
