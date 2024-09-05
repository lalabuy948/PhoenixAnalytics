"use client";

import * as React from "react";
import { format } from "date-fns";
import { Bar, BarChart, CartesianGrid, XAxis } from "recharts";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

import {
  ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

import { DateRange } from "./DateRange";
import { useSharedIntervalState } from "./IntervalHook";

const chartConfig = {
  views: {
    label: "Total requests",
  },
  hits: {
    label: "Total requests",
    color: "hsl(var(--chart-1))",
  },
} satisfies ChartConfig;

type ChartData = {
  date: string;
  requests: number;
};

export function RequestsChart({
  chartData,
  dateRange,
  pushEvent,
}: {
  chartData: ChartData[];
  dateRange: DateRange;
  pushEvent: any;
}) {
  const { interval, setInterval } = useSharedIntervalState();
  const updateInterval = (value: string) => {
    setInterval(value);

    pushEvent("set_interval", {
      value: {
        interval: value,
      },
    });
  };

  return (
    <Card>
      <CardHeader className="flex items-center gap-2 py-5 space-y-0 border-b sm:flex-row">
        <div className="grid flex-1 gap-1 text-center sm:text-left">
          <CardTitle>Total requests</CardTitle>
          <CardDescription>
            Showing total requests for {format(dateRange.from, "dd LLL, y")} -{" "}
            {format(dateRange.to, "dd LLL, y")}
          </CardDescription>
        </div>
        <Select value={interval} onValueChange={updateInterval}>
          <SelectTrigger
            className="w-[160px] rounded-lg sm:ml-auto"
            aria-label="Select a value"
          >
            <SelectValue placeholder="Interval" />
          </SelectTrigger>
          <SelectContent className="rounded-xl">
            <SelectItem value="hour" className="rounded-lg">
              Per hour
            </SelectItem>
            <SelectItem value="day" className="rounded-lg">
              Per day
            </SelectItem>
            <SelectItem value="month" className="rounded-lg">
              Per month
            </SelectItem>
          </SelectContent>
        </Select>
      </CardHeader>
      <CardContent className="px-2 sm:p-6">
        <ChartContainer
          config={chartConfig}
          className="aspect-auto h-[250px] w-full"
        >
          <BarChart
            accessibilityLayer
            data={chartData}
            margin={{
              left: 12,
              right: 12,
            }}
          >
            <CartesianGrid vertical={false} />
            <XAxis
              dataKey="date"
              tickLine={false}
              axisLine={false}
              tickMargin={8}
              minTickGap={32}
              tickFormatter={(value) => {
                const date = new Date(value);
                return date.toLocaleDateString("en-US", {
                  month: "short",
                  ...(interval !== "month" && { day: "numeric" }),
                  ...(interval === "month" && { year: "numeric" }),
                });
              }}
            />
            <ChartTooltip
              content={
                <ChartTooltipContent
                  className="w-[170px]"
                  nameKey="views"
                  labelFormatter={(value) => {
                    return new Date(value).toLocaleDateString("en-US", {
                      month: "short",
                      year: "numeric",
                      ...(interval !== "month" && { day: "numeric" }),
                      ...(interval === "hour" && { hour: "numeric" }),
                    });
                  }}
                />
              }
            />
            <Bar dataKey="hits" fill={`var(--color-hits)`} />
          </BarChart>
        </ChartContainer>
      </CardContent>
    </Card>
  );
}
