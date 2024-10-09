"use client";

import * as React from "react";
import { format } from "date-fns";
import { Area, AreaChart, CartesianGrid, XAxis } from "recharts";

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
  ChartLegend,
  ChartLegendContent,
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

import { useSharedIntervalState } from "./IntervalHook";

const chartConfig = {
  visitors: {
    label: "Visitors",
  },
  total: {
    label: "Total",
    color: "hsl(var(--chart-1))",
  },
  unique: {
    label: "Unique",
    color: "hsl(var(--chart-2))",
  },
} satisfies ChartConfig;

type ChartData = {
  date: string;
  total_visits: number;
  unique_visits: number;
};

type DateRange = {
  from: Date;
  to: Date;
};

export function VisitsChart({
  chartData,
  dateRange,
  pushEvent,
}: {
  chartData: ChartData[];
  dateRange: DateRange;
  intervalx: string;
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
          <CardTitle>Total visits</CardTitle>
          <CardDescription>
            Showing total visits for {format(dateRange.from, "dd LLL, y")} -{" "}
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
      <CardContent className="px-2 pt-4 sm:px-6 sm:pt-6">
        <ChartContainer
          config={chartConfig}
          className="aspect-auto h-[250px] w-full"
        >
          <AreaChart data={chartData}>
            <defs>
              <linearGradient id="fillTotal" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="var(--color-total)"
                  stopOpacity={0.8}
                />
                <stop
                  offset="95%"
                  stopColor="var(--color-total)"
                  stopOpacity={0.1}
                />
              </linearGradient>
              <linearGradient id="fillUnique" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="var(--color-unique)"
                  stopOpacity={0.8}
                />
                <stop
                  offset="95%"
                  stopColor="var(--color-unique)"
                  stopOpacity={0.1}
                />
              </linearGradient>
            </defs>
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
              cursor={false}
              content={
                <ChartTooltipContent
                  labelFormatter={(value) => {
                    return new Date(value).toLocaleDateString("en-US", {
                      month: "short",
                      year: "numeric",
                      ...(interval !== "month" && { day: "numeric" }),
                      ...(interval === "hour" && { hour: "numeric" }),
                    });
                  }}
                  indicator="dot"
                />
              }
            />
            <Area
              dataKey="total"
              type="natural"
              fill="url(#fillTotal)"
              stroke="var(--color-total)"
              stackId="a"
            />
            <Area
              dataKey="unique"
              type="natural"
              fill="url(#fillUnique)"
              stroke="var(--color-unique)"
              stackId="b"
            />
            <ChartLegend content={<ChartLegendContent />} />
          </AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
  );
}
