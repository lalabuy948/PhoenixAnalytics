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

import { DateRange } from "./DateRange";
import { useSharedIntervalState } from "./IntervalHook";

const chartConfig = {
  oks: {
    label: "200s",
    color: "hsl(var(--chart-5))",
  },
  redirs: {
    label: "300s",
    color: "hsl(var(--chart-4))",
  },
  errors: {
    label: "400s",
    color: "hsl(var(--chart-2))",
  },
  fails: {
    label: "500s",
    color: "hsl(var(--chart-1))",
  },
} satisfies ChartConfig;

type ChartData = {
  date: string;
  oks: number;
  redirs: number;
  erorrs: number;
  fails: number;
};

export function StatusChart({
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
          <CardTitle>HTTP Statuses</CardTitle>
          <CardDescription>
            Showing HTTP statuses for the {format(dateRange.from, "dd LLL, y")}{" "}
            - {format(dateRange.to, "dd LLL, y")}
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
              <linearGradient id="fillOks" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="var(--color-oks)"
                  stopOpacity={0.8}
                />
                <stop
                  offset="95%"
                  stopColor="var(--color-oks)"
                  stopOpacity={0.1}
                />
              </linearGradient>
              <linearGradient id="fillRedirs" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="var(--color-redirs)"
                  stopOpacity={0.8}
                />
                <stop
                  offset="95%"
                  stopColor="var(--color-redirs)"
                  stopOpacity={0.1}
                />
              </linearGradient>
              <linearGradient id="fillErrors" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="var(--color-errors)"
                  stopOpacity={0.8}
                />
                <stop
                  offset="95%"
                  stopColor="var(--color-errors)"
                  stopOpacity={0.1}
                />
              </linearGradient>
              <linearGradient id="fillFails" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="var(--color-fails)"
                  stopOpacity={0.8}
                />
                <stop
                  offset="95%"
                  stopColor="var(--color-fails)"
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
              dataKey="oks"
              type="natural"
              fill="url(#fillOks)"
              stroke="var(--color-oks)"
              stackId="a"
            />
            <Area
              dataKey="redirs"
              type="natural"
              fill="url(#fillRedirs)"
              stroke="var(--color-redirs)"
              stackId="b"
            />
            <Area
              dataKey="errors"
              type="natural"
              fill="url(#fillErrors)"
              stroke="var(--color-errors)"
              stackId="c"
            />
            <Area
              dataKey="fails"
              type="natural"
              fill="url(#fillFails)"
              stroke="var(--color-fails)"
              stackId="d"
            />
            <ChartLegend content={<ChartLegendContent />} />
          </AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
  );
}
